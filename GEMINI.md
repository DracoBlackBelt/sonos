# Sonos for Toon

A QML application for the **Toon smart thermostat** (by Quby/Eneco) that provides a user interface to control Sonos speakers. It acts as a client for the [node-sonos-http-api](https://github.com/jishi/node-sonos-http-api).

## Project Overview

*   **Purpose:** Control Sonos playback, zones, favorites, and playlists from the Toon display.
*   **Target Platform:** Toon 1 and Toon 2 (determined by the `isNxt` flag).
*   **Main Technologies:**
    *   **Qt Quick 2.1 / QML:** For the user interface.
    *   **JavaScript:** Embedded within QML for logic and API interaction.
    *   **node-sonos-http-api:** External middleware required to communicate with Sonos speakers.
*   **Key Features:**
    *   Playback controls (play, pause, skip, volume, shuffle).
    *   Zone management and selection.
    *   Sonos and Spotify playlist support.
    *   Spotify integration (OAuth flow).
    *   Text-to-Speech (TTS) audio messages.
    *   Football scores integration (announcing goals via TTS).

## Architecture

### State and API Management (`SonosApp.qml`)
The application follows a centralized state model. `SonosApp.qml` (extending the Toon `App` type) holds all global state, including:
*   Playback information (artist, title, album art, elapsed time).
*   Configuration settings (IP/port of the node API, zone names).
*   Spotify tokens and user data.
*   Timers for polling state (`sonosPlayInfoTimer`) and track progress (`sonosTrackTimer`).

### Communication
All communication with the Sonos speakers is done via `XMLHttpRequest` hitting the `node-sonos-http-api` endpoints:
`http://<connectionPath>/<zone>/<command>`

**Key Utility:** `simpleSynchronous(request, callback, parameter)`
*   **Request:** The full API URL.
*   **Callback:** (Optional) Function to execute on success (HTTP 200).
*   **Parameter:** (Optional) Data to pass to the callback.
*   **Hardening:** Includes `timeout` (1500ms) and state checks to prevent blocking the UI.

## Development Conventions
*   **Resolution Independence:** Use the `isNxt` property to handle scaling differences between Toon 1 and Toon 2.
*   **Asynchronous Calls:** Use `XMLHttpRequest` for all network requests. **Always** include `onerror` and `ontimeout` handlers for critical paths.
*   **Safe Parsing:** **Always** wrap `JSON.parse` calls in `try-catch` blocks to handle malformed API responses or corrupted local files.
*   **Input Sanitization:** **Always** use `encodeURIComponent()` when constructing API URLs with user input or zone names.
*   **Translation:** String literals should use `qsTr()` for localization support (files in `lang/`).
