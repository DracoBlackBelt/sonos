# AGENTS.md

Compact guide for OpenCode sessions. This is the canonical agent file; `CLAUDE.md` and `GEMINI.md` only point here.

## What this is

QML app for the Toon smart thermostat (module `apps.sonos`). Controls Sonos speakers through the [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api) middleware (default port 5005), with Spotify playlists via OAuth and text-to-speech messages. No build step, no tests, no linter, no CI, not a git repo — do not look for or add them.

## Deploy / verify

```bash
scp -O -r -oHostKeyAlgorithms=+ssh-rsa *.qml *.js qmldir drawables root@<toon-ip>:/qmf/qml/apps/sonos/
ssh -oHostKeyAlgorithms=+ssh-rsa root@<toon-ip> killall qt-gui
```

`-O` (no sftp-server on device) and `+ssh-rsa` (old host key) are both required. Icons are referenced by relative path (`drawables/...`), so `drawables/` must sit in the app's install dir next to the QML. No local way to run QML; verify by careful reading. `simpleSynchronous` and date/format helpers are engine-agnostic ES5 and can be brace-extracted and sanity-checked with `node`.

## Architecture

- `SonosApp.qml` — central `App`: all state, timers, API functions, settings I/O, widget registration (in `function init()`, NOT `Component.onCompleted`). Screens read state through `app`.
- Sonos commands: `http://<connectionPath>/<zone>/<command>` with `connectionPath` = `<ip>:<port>`; state polled by `sonosPlayInfoTimer` (5000 ms active / 20000 ms dimmed), `sonosTrackTimer` ticks elapsed time every 1000 ms, `startupTokenTimer` waits 15 s after boot before the first token refresh, `tokenRefreshTimer` re-fires every **55 min** (`interval` set at runtime to 3300000).
- `simpleSynchronous(request, callback, parameter)` is the fire-and-forget XHR helper (sets `timeout=1500`; device timeout support is unreliable, so it mainly guards via readyState/status checks).

| File | Role |
|---|---|
| `MenuScreen.qml` | IP/port, systray toggle, football-scores toggle (`voetbalTussenstanden` + `sonosNameVoetbalApp`), Spotify setup |
| `MediaScreen.qml` | Now-playing: artwork, controls, queue, position/volume slider (`drawables/volumeBar*.png`) |
| `FavoritesScreen.qml` | Sonos favourites/playlists, Spotify playlists, line-in, audio-message button |
| `MediaSelectZone(.Delegate).qml` | Zone picker (`/zones`) |
| `MessageScreen(.Delegate).qml` | TTS audio message config |
| `SpotifyLoginScreen.qml` | Enter client ID/secret, open auth URL, paste code |
| `SpotifyMusicSearchScreen.qml` | Search Spotify catalogue, keeps last 10 played (`recentlyPlayed`) |
| `SonosTile.qml` / `MediaTray.qml` | Home tile / optional systray icon |
| `EditTextLabel4421.qml` | Shared input widget copy (also in calender/buienradar) — mirror changes, don't dedupe |

## Spotify auth model (since 1.4.0 — old docs are wrong)

- OAuth **authorization-code** flow (`grant_type=authorization_code`, then `grant_type=refresh_token`) against `https://accounts.spotify.com/api/token`. Basic auth header built with a custom `customBtoa()` — QML has no native `btoa`.
- `redirect_uri` is hardcoded to `https://example.com` in BOTH `buildSpotifyAuthUrl()` and `exchangeCodeForToken()`; a mismatch breaks token exchange silently — keep them in sync.
- Client secret + tokens live in a **separate file** `/mnt/data/tsc/sonos.spotifyToken.json` (`saveTokenFile()`); `sonos.userSettings.json` holds everything else (incl. `spotifyClientId`/`spotifyDisplayName`) but NOT the secret or the access token. On boot `readSettings()` still falls back to `settings['spotifyClientSecret']` if present (`SonosApp.qml:253`) for pre-1.4.1 devices — that read is the only remaining coupling; never write the secret back into settings. The login screen pre-fills the client ID but never the secret (`SpotifyLoginScreen.qml:23`).
- Changelog/older docs mention `selectedPlaylistUser`, `musicSource`, `spotifyUserNames`/`spotifyUserIDs`, `SpotifyCredentialsScreen.qml`, `SpotifyEditUsersScreen.qml`, `SpotifySelectUser.qml` — all removed in 1.4.0. Don't reintroduce the pattern.
- `spotify-login.sh` is a PC-side helper (run on your laptop, not the device): does the OAuth dance with curl and pushes tokens to the device via `sshpass`. It hardcodes IP `192.168.10.68` and password `toon` — edit both before running.

## Platform rules (apply to every file here)

- **ES5 only** — Qt5 JavaScriptCore: `var`, no `let`/`const`, no arrow functions, no template strings, no ES6 methods.
- **No fetch API** — all HTTP and file writes via `XMLHttpRequest`; wrap `JSON.parse` in `try-catch`; `encodeURIComponent()` user/zone input in URLs (not every existing call site does — do it in new code).
- Settings read via `FileIO` from `/mnt/data/tsc/sonos.userSettings.json`, written via XHR PUT.
- Sizes/margins branch on `isNxt` (true = Toon 2/NXT); colors: `(typeof dimmableColors !== 'undefined') ? dimmableColors.X : colors.X`.
- UI strings are Dutch, wrapped in `qsTr()`; `lang/*.qm` are compiled translations.

## Releases

Bump `version.txt` (currently `1.4.1`) and prepend a brief block to `Changelog.txt` together when changing behavior. Spotify/auth/HTTP-layer changes go through the security checklist in `.claude/agents/spotify-security-reviewer.md` before release.
