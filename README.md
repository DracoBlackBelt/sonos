# Toon Sonos App

A QML app for the [Toon smart thermostat](https://www.quby.com/) that controls Sonos speakers from the Toon screen. Distributed as `apps.sonos`.

## Features

- Now-playing screen: artwork, play/pause/skip/shuffle, position and volume slider, queue view
- Multi-zone support with a zone picker
- Sonos favourites and playlists
- Spotify integration: log in with your own Spotify app credentials (OAuth), search the catalogue, last-10 played list
- Text-to-speech audio messages (e.g. "het eten staat klaar") on any zone
- Football score announcements via TTS (toggleable)
- Home-screen tile and optional system tray icon

## Prerequisites

You need [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api) running on your network (default port 5005). The app is a client of that API; it does not talk to Sonos directly.

## Installation

The Toon's old SSH server needs legacy options (`-O` because the device has no sftp-server, `ssh-rsa` for the host key). Icons live in `drawables/` and must be deployed alongside the QML:

```bash
scp -O -r -oHostKeyAlgorithms=+ssh-rsa *.qml *.js qmldir drawables root@<toon-ip>:/qmf/qml/apps/sonos/
```

To apply changes, restart the Toon GUI (this restarts all apps):

```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@<toon-ip>
killall qt-gui
```

## Configuration

Open the Sonos menu entry on your Toon to set the API host/IP and port, enable the tray icon and football scores, and configure Spotify. Spotify can also be connected from your PC with `spotify-login.sh` (edit the device IP and password at the top of the script first; requires `sshpass`).

Settings are stored at `/mnt/data/tsc/sonos.userSettings.json`; the Spotify client id/secret and tokens are kept in `/mnt/data/tsc/sonos.spotifyToken.json` (the only file containing secrets) on the device.

## Compatibility

Works on both Toon 1 and Toon 2 / NXT hardware. The app branches on the platform-provided `isNxt` boolean for layout differences between the two screen sizes.

## Version

Current version: **1.4.2** — see [Changelog.txt](Changelog.txt) for full history.
