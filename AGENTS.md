# AGENTS.md

Compact guide for OpenCode sessions. This is the canonical agent file; `CLAUDE.md` and `GEMINI.md` only point here.

## What this is

QML app for the Toon smart thermostat (module `apps.sonos`). Controls Sonos speakers through the [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api) middleware (default port 5005), with Spotify playlists via OAuth and text-to-speech messages. No build step, no tests, no linter, no CI. Unlike the rest of the Toon workspace, this folder **is** its own git repo (`git diff`/`git log` are useful for review; don't commit unless asked).

## Deploy / verify

```bash
scp -O -r -oHostKeyAlgorithms=+ssh-rsa *.qml *.js qmldir drawables root@<toon-ip>:/qmf/qml/apps/sonos/
ssh -oHostKeyAlgorithms=+ssh-rsa root@<toon-ip> killall qt-gui
```

`-O` (no sftp-server on device) and `+ssh-rsa` (old host key) are both required. Icons are referenced by relative path (`drawables/...`), so `drawables/` must sit in the app's install dir next to the QML. No local way to run QML; verify by careful reading. `simpleSynchronous` and date/format helpers are engine-agnostic ES5 and can be brace-extracted and sanity-checked with `node`.

## Architecture

- `SonosApp.qml` — central `App`: all state, timers, API functions, settings I/O, widget registration (in `function init()`, NOT `Component.onCompleted`). Screens read state through `app`.
- Sonos commands: `http://<connectionPath>/<zone>/<command>` with `connectionPath` = `<ip>:<port>`; ALWAYS build these via the `sonosUrl(cmd)` / `zoneUrl(zone, cmd)` helpers on `app` (they `encodeURIComponent` the zone name; never hand-concatenate `sonosName` into a URL). EXCEPTION: Spotify URIs passed to `/<zone>/spotify/{now,next,queue}/<uri>` must stay RAW (`spotify:track:...`) — the http-api regex-matches the un-decoded path and chokes on `%3A`; colons are legal in a path segment. Name parameters (playlist/favorite/say) ARE encoded; those handlers decode. State polled by `sonosPlayInfoTimer` (5000 ms active / 20000 ms dimmed) with an in-flight flag + `stateWatchdog` Timer (15 s) — device `xhr.timeout` is unreliable, the watchdog is the real bound; `sonosTrackTimer` ticks elapsed time every 1000 ms, `startupTokenTimer` waits 15 s after boot before the first token refresh, `tokenRefreshTimer` re-fires every **55 min** and is (re)started after *every* refresh attempt — including failed ones — so Spotify recovers without a reboot.
- `apiGet(request, callback, parameter, done)` is the XHR helper: `callback(parameter)` on HTTP 200, `done()` always at completion (used by `FavoritesScreen.favGet` for throbber handling). MediaScreen also guards `updateQueue` with its own `queueInFlight` flag + `queueWatchdog`.

| File | Role |
|---|---|
| `MenuScreen.qml` | IP/port, systray toggle, football-scores toggle (`voetbalTussenstanden` + `sonosNameVoetbalApp`), Spotify setup, Check Connection (with failure dialogs) |
| `MediaScreen.qml` | Now-playing: artwork, controls, queue, position/volume slider (`drawables/volumeBar*.png`) |
| `FavoritesScreen.qml` | Sonos favourites/playlists, Spotify search + last-10 played, line-in, audio-message button |
| `MediaSelectZone(.Delegate).qml` | Zone picker (`/zones`), per-zone controls |
| `MessageScreen(.Delegate).qml` | TTS audio message config |
| `SpotifyLoginScreen.qml` | Enter client ID/secret, open auth URL, paste code |
| `SonosTile.qml` / `MediaTray.qml` | Home tile / optional systray icon |
| `EditTextLabel4421.qml` | Shared input widget copy (also in calender/buienradar) — mirror changes, don't dedupe |

## Spotify auth model (since 1.4.0 — old docs are wrong)

- OAuth **authorization-code** flow (`grant_type=authorization_code`, then `grant_type=refresh_token`) against `https://accounts.spotify.com/api/token`. Basic auth header built with a custom `customBtoa()` — QML has no native `btoa`. Keep `customBtoa` ES5-only (`var`); the old JSC may fail to parse `let`/`const` and would break the whole component.
- `redirect_uri` is hardcoded to `https://example.com` in BOTH `buildSpotifyAuthUrl()` and `exchangeCodeForToken()` (as `https%3A%2F%2Fexample.com`); a mismatch breaks token exchange silently — keep them in sync. `spotify-login.sh` uses the same value.
- Credentials/tokens are held in plain string properties `spotifyClientId` / `spotifyClientSecret` / `spotifyAccessToken` / `spotifyRefreshToken` (NOT in-place mutation of a `variant` object — those can silently no-op as QVariantMap copies). `/mnt/data/tsc/sonos.spotifyToken.json` (`saveTokenFile()`) holds all four; `sonos.userSettings.json` holds everything else (incl. `spotifyClientId`/`spotifyDisplayName`) but `saveSettings()` rebuilds the object from a whitelist so a secret/refresh token can never leak back into it. On boot `readSettings()` still accepts a leftover `spotifyClientSecret`/`spotifyRefreshToken` in the settings file from pre-1.4.1 devices, copies them to the token file and rewrites the settings file without them (`spotify-login.sh` likewise only writes clientId/status to settings). Never write the secret into userSettings again. The login screen pre-fills the client ID but never the secret, and persists both to the token file as soon as the user submits step 0.
- `disconnectSpotify()` clears refresh + access token in memory AND via `saveTokenFile()`; clientId/secret are kept for easy re-login.
- Changelog/older docs mention `selectedPlaylistUser`, `musicSource`, `spotifyUserNames`/`spotifyUserIDs`, `SpotifyCredentialsScreen.qml`, `SpotifyEditUsersScreen.qml`, `SpotifySelectUser.qml`, `SpotifyMusicSearchScreen.qml`, `fetchSpotifyPlaylists`/`spotifyPlaylists` — all removed (1.4.0 / 1.4.2). Don't reintroduce the pattern. Spotify playlist *browsing* is not a feature; only catalogue search + recents in `FavoritesScreen`.
- `sonosNameVoetbalApp` is either "" (unset) or a real zone name — the old Dutch placeholder string is sanitized on read and never stored.
- `spotify-login.sh` is a PC-side helper (run on your laptop, not the device): does the OAuth dance with curl and pushes tokens to the device via `sshpass`. It hardcodes IP `192.168.10.68` and password `toon` — edit both before running.

## Platform rules (apply to every file here)

- **ES5 only** — Qt5 JavaScriptCore: `var`, no `let`/`const`, no arrow functions, no template strings, no ES6 methods.
- **No fetch API** — all HTTP and file writes via `XMLHttpRequest`; wrap `JSON.parse` in `try-catch`; build every Sonos command URL through `app.sonosUrl()`/`app.zoneUrl()` so zone names are encoded (since 1.4.2 all call sites do).
- Settings read via `FileIO` from `/mnt/data/tsc/sonos.userSettings.json`, written via XHR PUT.
- Sizes/margins branch on `isNxt` (true = Toon 2/NXT); colors: `(typeof dimmableColors !== 'undefined') ? dimmableColors.X : colors.X`.
- UI strings are Dutch, wrapped in `qsTr()`; `lang/*.qm` are compiled translations.

## Releases

Bump `version.txt` (currently `1.4.3`) and prepend a brief block to `Changelog.txt` together when changing behavior. Spotify/auth/HTTP-layer changes go through the security checklist in `.claude/agents/spotify-security-reviewer.md` before release.
