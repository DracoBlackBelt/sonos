# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A QML app for the **Toon smart thermostat** (by Quby/Eneco) that controls Sonos speakers via the [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api). Written in Qt Quick 2.1 QML with embedded JavaScript.

There is no build step. Files are deployed directly to the Toon device (typically via SSH or the Toon app store). The module is registered as `apps.sonos` in `qmldir`.

## Deployment

Copy QML files to the Toon device at the app's install path, then restart the GUI or reload the app. Settings are persisted on device at `/mnt/data/tsc/sonos.userSettings.json`.

## Architecture

### State and API layer — `SonosApp.qml`

All application state (playback info, settings, Spotify tokens, zone list) lives in `SonosApp.qml`, which extends the Toon `App` base type. Every screen accesses state through the `app` reference.

**Timers in SonosApp:**
- `sonosPlayInfoTimer` — polls `/state` every 5 s (active) or 20 s (dimmed)
- `sonosTrackTimer` — increments `trackElapsedTime` locally every 1 s during playback
- `tokenRefreshTimer` — refreshes Spotify bearer token every ~1 hour (3 599 s)

**Sonos HTTP API calls** hit `http://<connectionPath>/<zone>/<command>`. The `connectionPath` is `<ip>:<port>` (default port 5005). All requests use `XMLHttpRequest` in QML.

**Spotify** uses the client credentials flow (`grant_type=client_credentials`) against `https://accounts.spotify.com/api/token`. A custom `customBtoa()` base64 encoder is used because QML lacks a native `btoa`.

### Screens

| File | Purpose |
|---|---|
| `SonosApp.qml` | App root: all state, timers, API functions, settings I/O |
| `MenuScreen.qml` | Configuration: IP/port, systray toggle, football scores toggle, Spotify setup |
| `MediaScreen.qml` | Now-playing: artwork, controls, position slider, queue |
| `FavoritesScreen.qml` | Favourites, playlists (Sonos or Spotify), audio message button |
| `MediaSelectZone.qml` | Zone picker when multiple Sonos zones exist |
| `MessageScreen.qml` | Text-to-speech audio message configuration |
| `SpotifyCredentialsScreen.qml` | Enter Spotify client ID/secret to enable integration |
| `SpotifyEditUsersScreen.qml` | Add/delete Spotify user accounts |
| `SpotifySelectUser.qml` | Choose which Spotify user's playlists to show |
| `SpotifyMusicSearchScreen.qml` | Search Spotify catalogue and play results |
| `SonosTile.qml` | Home screen tile (dim-state shows current track) |
| `MediaTray.qml` | System tray icon (optional, toggled via settings) |

### Layout flag

`isNxt` is a Toon platform boolean: `true` for Toon 2 (higher resolution), `false` for original Toon. Use it for sizing/positioning differences.

### Settings

`saveSettings()` / `readSettings()` in `SonosApp.qml` read and write a flat JSON object to `/mnt/data/tsc/sonos.userSettings.json`. The `FileIO` QML type handles file access; HTTP PUT writes the file.

### Spotify user flow

`selectedPlaylistUser = 0` means Sonos library; values `> 0` index into `spotifyUserNames`/`spotifyUserIDs` arrays. `musicSource` property reflects this ("Sonos" or "Spotify").

## Version

Maintained in `version.txt`. Update both `version.txt` and `Changelog.txt` when releasing.
