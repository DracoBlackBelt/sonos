//
// Sonos app by Harmen Bartelink
// Further enhanced by Toonz
//

import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import ScreenStateController 1.0
import FileIO 1.0

App {
	id: root
	property url trayUrl : "MediaTray.qml"
	property url menuScreenUrl : "MenuScreen.qml"
	property url messageScreenUrl : "MessageScreen.qml"
	property url mediaSelectZoneUrl : "MediaSelectZone.qml"
	property url spotifyLoginScreenUrl : "SpotifyLoginScreen.qml"
	property url tileUrl : "SonosTile.qml"
	property url thumbnailIcon: "qrc:/tsc/SonosThumb.png"
	property SpotifyLoginScreen spotifyLoginScreen
	property MenuScreen menuScreen
	property MediaScreen mediaScreen
	property MessageScreen messageScreen
	property MediaSelectZone mediaSelectZone
	property FavoritesScreen favoritesScreen

	property SystrayIcon mediaTray
	property bool showSonosIcon : true
	property bool playFootballScores : true
	property string playbackState
	property variant playlists : []
	property variant favourites : []
	property variant queue : []
	property variant sonoslist : []

	property string spotifyStatus : "toBeConfigured"
	property string spotifyClientId : ""
	property string spotifyClientSecret : ""
	property string spotifyAccessToken : ""
	property string spotifyRefreshToken : ""
	property string spotifyDisplayName : ""
	property variant recentlyPlayed : []        // [{name, uri}], last 10 played via Spotify search

	property string sonosName
	property string sonosNameVoetbalApp
	property string zoneToSelect
	property bool sonosNameIsGroup : false
	property string ipadresLabel
	property string poortnummer
	property string actualArtist
	property string actualTitle
	property string nowPlayingImage
	property bool playButtonVisible : true
	property bool pauseButtonVisible : false
	property bool shuffleButtonVisible : true
	property bool shuffleOnButtonVisible : false
	property variant settings : {
			"showSonosIcon" : "true",
			"sonosName" : "",
			"sonosNameVoetbalApp" : "",
			"path" : "",
			"messageText" : "",
			"messageVolume" : "",
			"messageSonosName" : "",
			"voetbalTussenstanden" : "",
			"spotifyStatus" : "",
			"spotifyClientId" : "",
			"spotifyDisplayName" : ""
		}

	property variant messageTextArray : ["Hallo","Hallo daar, het eten staat klaar"]
	property string messageSonosName : "Alle"
	property int messageVolume : 20
	property int trackDuration
	property int trackElapsedTime
	property bool showSlider : false

	property string connectionPath

	FileIO {
		id: sonosSettingsFile
		source: "file:///mnt/data/tsc/sonos.userSettings.json"
	}

	FileIO {
		id: sonosTokenFile
		source: "file:///mnt/data/tsc/sonos.spotifyToken.json"
	}

	QtObject {
		id: p
		property url favoritesScreenUrl : "FavoritesScreen.qml"
		property url mediaScreenUrl : "MediaScreen.qml"
		property bool stateInFlight : false
	}

	function init() {
		registry.registerWidget("systrayIcon", trayUrl, this, "mediaTray");
		registry.registerWidget("screen", p.mediaScreenUrl, this, "mediaScreen");
		registry.registerWidget("screen", p.favoritesScreenUrl, this, "favoritesScreen");
		registry.registerWidget("screen", menuScreenUrl, this, "menuScreen");
		registry.registerWidget("screen", messageScreenUrl, this, "messageScreen");
		registry.registerWidget("screen", mediaSelectZoneUrl, this, "mediaSelectZone");
		registry.registerWidget("screen", spotifyLoginScreenUrl, this, "spotifyLoginScreen");
		registry.registerWidget("menuItem", null, this, null, {objectName: "sonosMenuItem", label: qsTr("Sonos"), image: thumbnailIcon, screenUrl: menuScreenUrl, weight: 120});
		registry.registerWidget("tile", tileUrl, this, null, {thumbLabel: qsTr("Sonos"), thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
	}

	Component.onCompleted: {
		readSettings();
	}

	Connections {
		target: screenStateController
		onScreenStateChanged: {
			if (screenStateController.screenState == ScreenStateController.ScreenColorDimmed || screenStateController.screenState == ScreenStateController.ScreenOff) {
				sonosPlayInfoTimer.stop();
				sonosPlayInfoTimer.interval = 20000;
				sonosPlayInfoTimer.start();
			} else {
				sonosPlayInfoTimer.stop();
				sonosPlayInfoTimer.interval = 5000;
				sonosPlayInfoTimer.start();
			}
		}
	}

	function updateAvailableZones() {
		var tmpSonosName = sonosName;
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onerror = function() { console.log("sonos: updateAvailableZones network error"); }
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						var newArray = [];
						var newName = tmpSonosName;
						var newIsGroup = false;
						if (response && response.length > 0) {
							for (var i = 0; i < response.length; i++) {
								var roomName = "";
								if (response[i]["coordinator"] && response[i]["coordinator"]["roomName"]) {
									roomName = response[i]["coordinator"]["roomName"];
								}
								if (roomName.length < 1) continue;
								var members = response[i]["members"];
								var tmpGroupFlag = (members && members.length > 1);
								if (newName == roomName) {
									newIsGroup = tmpGroupFlag;
								}
								newArray.push({name: roomName, isGroup: tmpGroupFlag});
							}
							sonoslist = newArray;
							// fall back to first zone if the stored name no longer exists
							if (newArray.length > 0 && newName.length > 0) {
								var found = false;
								for (var j = 0; j < newArray.length; j++) {
									if (newArray[j]["name"] == newName) { found = true; break; }
								}
								if (!found) {
									newName = newArray[0]["name"];
									newIsGroup = newArray[0]["isGroup"];
								}
							}
						}
						// only assign on success so a failed poll keeps the old zone
						sonosName = newName;
						sonosNameIsGroup = newIsGroup;
					} catch(e) {
						console.log("sonos: error parsing zones response: " + e);
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+connectionPath+"/zones");
		xmlhttp.send();
	}

	function saveshowSonosIcon(text) {
		showSonosIcon = (text == "Yes");
   		saveSettings();
		if (mediaTray) {
			if (showSonosIcon) {
				mediaTray.show();
			} else {
				mediaTray.hide();
			}
		}
	}

	function saveplayScores(text) {
		playFootballScores = (text == "Yes");
   		saveSettings();
	}

	function saveSettings() {
		var tmpTrayIcon = showSonosIcon ? "true" : "false";
		var tmpVoetbal = playFootballScores ? "true" : "false";

		// rebuild from scratch: never carries over legacy keys (e.g. a pre-1.4.1 spotifyClientSecret),
		// and never stores the client secret or any token here — those live in the token file only
		settings = {
			"showSonosIcon": tmpTrayIcon,
			"sonosName": sonosName,
			"sonosNameVoetbalApp": sonosNameVoetbalApp,
			"path": connectionPath,
			"messageText": messageTextArray,
			"messageSonosName": messageSonosName,
			"messageVolume": messageVolume,
			"voetbalTussenstanden": tmpVoetbal,
			"spotifyStatus": spotifyStatus,
			"spotifyClientId": spotifyClientId,
			"spotifyDisplayName": spotifyDisplayName,
			"recentlyPlayed": recentlyPlayed
		};

		var saveFile = new XMLHttpRequest();
		saveFile.open("PUT", "file:///mnt/data/tsc/sonos.userSettings.json");
		saveFile.send(JSON.stringify(settings));
	}

	function saveTokenFile() {
		var saveFile = new XMLHttpRequest();
		saveFile.open("PUT", "file:///mnt/data/tsc/sonos.spotifyToken.json");
		saveFile.send(JSON.stringify({
			"spotifyClientId": spotifyClientId,
			"spotifyClientSecret": spotifyClientSecret,
			"refresh_token": spotifyRefreshToken,
			"access_token": spotifyAccessToken
		}));
	}

	// loads the token file into the string properties; returns which fields were present
	function readTokenFile() {
		var found = { hasSecret: false, hasRefresh: false };
		var tokenString = sonosTokenFile.read();
		if (tokenString && tokenString.length > 2) {
			try {
				var tokenData = JSON.parse(tokenString);
				if (tokenData["spotifyClientId"]) spotifyClientId = tokenData["spotifyClientId"];
				if (tokenData["spotifyClientSecret"]) { spotifyClientSecret = tokenData["spotifyClientSecret"]; found.hasSecret = true; }
				if (tokenData["refresh_token"]) { spotifyRefreshToken = tokenData["refresh_token"]; found.hasRefresh = true; }
				if (tokenData["access_token"]) spotifyAccessToken = tokenData["access_token"];
			} catch(e) {
				// deliberately not logging e: JSON parse errors can echo fragments of the (secret-bearing) input
				console.log("sonos: invalid token file");
			}
		}
		return found;
	}

	function readSettings() {
		var legacySecret = "";
		var legacyRefresh = "";
		var migrated = false;
		var settingsString = sonosSettingsFile.read();
		try {
			settings = JSON.parse(settingsString);
			if (settings['showSonosIcon']) showSonosIcon = (settings['showSonosIcon'] == "true");
			if (settings['sonosName']) sonosName = (settings['sonosName']);
			if (settings['sonosNameVoetbalApp']) sonosNameVoetbalApp = (settings['sonosNameVoetbalApp']);
			if (settings['messageVolume']) messageVolume = parseInt(settings['messageVolume']);
			if (settings['messageSonosName']) messageSonosName = (settings['messageSonosName']);
			if (settings['messageText']) messageTextArray = (settings['messageText']);
			if (settings['voetbalTussenstanden']) playFootballScores = (settings['voetbalTussenstanden'] == "true");
			if (settings['spotifyStatus']) spotifyStatus = settings['spotifyStatus'];
			if (settings['spotifyClientId']) spotifyClientId = settings['spotifyClientId'];
			if (settings['spotifyDisplayName']) spotifyDisplayName = settings['spotifyDisplayName'];
			if (settings['recentlyPlayed']) recentlyPlayed = settings['recentlyPlayed'];
			// pre-1.4.1 devices: secret/refresh token may still sit in the settings file;
			// remember them as fallback (token file wins) and migrate them out below
			if (settings['spotifyClientSecret']) { legacySecret = settings['spotifyClientSecret']; migrated = true; }
			if (settings['spotifyRefreshToken']) { legacyRefresh = settings['spotifyRefreshToken']; migrated = true; }
			delete settings['spotifyClientSecret'];
			delete settings['spotifyRefreshToken'];

			// never persist the old "click to select a zone" placeholder as a zone name
			if (sonosNameVoetbalApp.indexOf("Klik om") == 0) sonosNameVoetbalApp = "";

			if (settings['path']) {
				connectionPath = (settings['path']);
				if (connectionPath.length > 0) {
					var pathVar = connectionPath;
					var splitVar = pathVar.split(":")
					ipadresLabel = splitVar[0];
					poortnummer = splitVar[1];
				}
				updateAvailableZones();
			}
		} catch(e) {
			console.log("sonos: error parsing settings: " + e);
		}

		var tokenInfo = readTokenFile();   // token file overrides settings
		if (legacySecret.length > 0 && !tokenInfo.hasSecret) spotifyClientSecret = legacySecret;
		if (legacyRefresh.length > 0 && !tokenInfo.hasRefresh) spotifyRefreshToken = legacyRefresh;
		if (migrated) {
			// complete the migration: secrets/tokens to the token file, settings file rewritten without them
			saveTokenFile();
			saveSettings();
		}

		if (spotifyStatus == "configured" && spotifyRefreshToken.length > 0) {
			startupTokenTimer.start();
		}
	}

	// URL helpers; zone names must be encoded (spaces and special chars are common in room names)
	function zoneUrl(zone, cmd) {
		return "http://" + connectionPath + "/" + encodeURIComponent(zone) + "/" + cmd;
	}

	function sonosUrl(cmd) {
		return zoneUrl(sonosName, cmd);
	}

	// Build the Spotify authorization URL for the user to visit
	function buildSpotifyAuthUrl() {
		var scope = "playlist-read-private%20playlist-read-collaborative";
		var redirectUri = "https%3A%2F%2Fexample.com";
		return "https://accounts.spotify.com/authorize?client_id=" + encodeURIComponent(spotifyClientId) +
			"&response_type=code" +
			"&redirect_uri=" + redirectUri +
			"&scope=" + scope;
	}

	// Exchange authorization code for access + refresh tokens
	function exchangeCodeForToken(code) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 10000;
		xmlhttp.onerror = function() { 
			spotifyStatus = "error";
			console.log("spotify: exchangeCodeForToken network error");
		}
		xmlhttp.ontimeout = function() {
			spotifyStatus = "error";
			console.log("spotify: exchangeCodeForToken timeout");
		}
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						if (!response["access_token"] || !response["refresh_token"]) {
							spotifyStatus = "error";
							return;
						}
						spotifyAccessToken = response["access_token"];
						spotifyRefreshToken = response["refresh_token"];
						spotifyStatus = "configured";
						saveSettings();
						saveTokenFile();
						fetchSpotifyUserProfile();
						tokenRefreshTimer.stop();
						tokenRefreshTimer.interval = 3300000;
						tokenRefreshTimer.start();
					} catch(e) {
						spotifyStatus = "error";
						console.log("spotify: malformed token response");
					}
				} else {
					spotifyStatus = "error";
				}
			}
		}
		var body = "grant_type=authorization_code" +
			"&code=" + encodeURIComponent(code) +
			"&redirect_uri=https%3A%2F%2Fexample.com";
		xmlhttp.open("POST", "https://accounts.spotify.com/api/token");
		xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		xmlhttp.setRequestHeader("Authorization", "Basic " + customBtoa(spotifyClientId + ":" + spotifyClientSecret));
		xmlhttp.send(body);
	}

	// Refresh the access token using the stored refresh token
	function refreshSpotifyAccessToken() {
		if (spotifyClientId.length == 0 || spotifyClientSecret.length == 0 || spotifyRefreshToken.length == 0) {
			return;
		}
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 10000;
		xmlhttp.onerror = function() { console.log("spotify: refreshSpotifyAccessToken network error"); }
		xmlhttp.ontimeout = function() { console.log("spotify: refreshSpotifyAccessToken timeout"); }
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						if (!response["access_token"]) return;
						spotifyAccessToken = response["access_token"];
						if (response["refresh_token"]) {
							spotifyRefreshToken = response["refresh_token"];
						}
						saveTokenFile();
					} catch(e) {
						console.log("spotify: malformed refresh response");
					}
				} else if (xmlhttp.status == 400 || xmlhttp.status == 401) {
					// Definitively invalid token — require re-login
					spotifyStatus = "toBeConfigured";
					spotifyRefreshToken = "";
					spotifyAccessToken = "";
					saveSettings();
					saveTokenFile();
				}
				// Any other status (network error, timeout) — keep token, retry on next timer tick
			}
		}
		var body = "grant_type=refresh_token&refresh_token=" + encodeURIComponent(spotifyRefreshToken);
		xmlhttp.open("POST", "https://accounts.spotify.com/api/token");
		xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		xmlhttp.setRequestHeader("Authorization", "Basic " + customBtoa(spotifyClientId + ":" + spotifyClientSecret));
		xmlhttp.send(body);
		// (re)schedule the next refresh unconditionally — also after transient failures,
		// otherwise a network outage at boot would leave Spotify dead until a reboot
		tokenRefreshTimer.stop();
		tokenRefreshTimer.interval = 3300000;
		tokenRefreshTimer.start();
	}

	// Fetch user's display name from Spotify profile
	function fetchSpotifyUserProfile() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 10000;
		xmlhttp.onerror = function() { console.log("spotify: fetchSpotifyUserProfile network error"); }
		xmlhttp.ontimeout = function() { console.log("spotify: fetchSpotifyUserProfile timeout"); }
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						spotifyDisplayName = response["display_name"] || response["id"] || "";
						saveSettings();
					} catch(e) {
						console.log("spotify: error parsing profile: " + e);
					}
				}
			}
		}
		xmlhttp.open("GET", "https://api.spotify.com/v1/me");
		xmlhttp.setRequestHeader("Authorization", "Bearer " + spotifyAccessToken);
		xmlhttp.send();
	}

	// Disconnect Spotify — clear user tokens and reset status (keeps clientId/secret for easy re-login)
	function disconnectSpotify() {
		spotifyStatus = "toBeConfigured";
		spotifyRefreshToken = "";
		spotifyAccessToken = "";
		spotifyDisplayName = "";
		tokenRefreshTimer.stop();
		saveSettings();
		saveTokenFile();
	}

	function addToRecentlyPlayed(name, uri) {
		var newList = [];
		newList.push({name: name, uri: uri});
		for (var i = 0; i < recentlyPlayed.length && newList.length < 10; i++) {
			if (recentlyPlayed[i]["uri"] !== uri) {
				newList.push(recentlyPlayed[i]);
			}
		}
		recentlyPlayed = newList;
		saveSettings();
	}

	// base64 of ASCII/Latin-1 strings (client id + secret). ES5 syntax only.
	function customBtoa(str) {
		var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		var encoded = '';
		var i = 0;

		while (i < str.length) {
			var c1 = str.charCodeAt(i++);
			var hasC2 = i < str.length;
			var c2 = hasC2 ? str.charCodeAt(i++) : 0;
			var hasC3 = i < str.length;
			var c3 = hasC3 ? str.charCodeAt(i++) : 0;

			var e1 = c1 >> 2;
			var e2 = ((c1 & 3) << 4) | (c2 >> 4);
			var e3 = ((c2 & 15) << 2) | (c3 >> 6);
			var e4 = c3 & 63;

			if (!hasC2) {
				encoded += chars.charAt(e1) + chars.charAt(e2) + '==';
			} else if (!hasC3) {
				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + '=';
			} else {
				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + chars.charAt(e4);
			}
		}

		return encoded;
	}

	// Fire-and-forget GET; callback(parameter) runs on HTTP 200 only,
	// optional done() runs at completion regardless of status.
	function apiGet(request, callback, parameter, done) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 4000;
		xmlhttp.onerror = function() {
			if (typeof(done) === 'function') { done(); }
		}
		xmlhttp.ontimeout = function() {
			if (typeof(done) === 'function') { done(); }
		}
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					if (typeof(callback) === 'function') {
						callback(parameter);
					}
				}
				if (typeof(done) === 'function') { done(); }
			}
		}
		xmlhttp.open("GET", request, true);
		xmlhttp.send();
	}

	Timer {
		id: stateWatchdog
		interval: 15000
		repeat: false
		running: false
		onTriggered: {
			// xhr timeout support is unreliable on this Qt build; if a poll neither
			// completed nor errored, assume it is stuck and allow the next one
			p.stateInFlight = false;
			console.log("sonos: state poll watchdog reset");
		}
	}

	function readSonosState() {
		if (p.stateInFlight) { return; }
		p.stateInFlight = true;
		stateWatchdog.restart();
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 4000;
		xmlhttp.onerror = function() { p.stateInFlight = false; stateWatchdog.stop(); console.log("sonos: readSonosState network error"); }
		xmlhttp.ontimeout = function() { p.stateInFlight = false; stateWatchdog.stop(); console.log("sonos: readSonosState timeout"); }
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				p.stateInFlight = false;
				stateWatchdog.stop();
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						var currentTrack = response['currentTrack'] || {};
						if (currentTrack['type'] == "track"){
							showSlider = true;
							actualArtist = "";
							actualTitle = "";
							if (currentTrack['title']) actualTitle = currentTrack['title'];
							if (currentTrack['artist']) actualArtist = currentTrack['artist'];
							if (currentTrack['duration']) trackDuration = currentTrack['duration'];
							if (typeof response['elapsedTime'] == 'number' && trackDuration > 0) {
								if (!mediaScreen || !mediaScreen.positionIndicatorDragActive) {
									trackElapsedTime = response['elapsedTime'];
									if (mediaScreen) {
										mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);
									}
								}
							}
							if ('absoluteAlbumArtUri' in currentTrack) {
								var tmpNowPlayingImage = currentTrack['absoluteAlbumArtUri'].replace("https://", "http://");
							} else {
								var tmpNowPlayingImage = "";
							}
							if (tmpNowPlayingImage !== nowPlayingImage) {
								nowPlayingImage = tmpNowPlayingImage;
							}
						}
						if (currentTrack['type'] == "radio"){
							showSlider = false;
							actualArtist = currentTrack['stationName'] || "";
							actualTitle = "";
							if (response['playbackState'] == "PLAYING") {
								actualTitle = currentTrack['title'] || "";
							}
							if ('absoluteAlbumArtUri' in currentTrack) {
								var tmpRadioImage = currentTrack['absoluteAlbumArtUri'].replace("https://", "http://");
							} else {
								var tmpRadioImage = "";
							}
							if (tmpRadioImage !== nowPlayingImage) {
								nowPlayingImage = tmpRadioImage;
							}
						}
						if (currentTrack['type'] != "track" && currentTrack['type'] != "radio") {
							// line-in, no queue loaded etc: don't keep showing the previous track
							actualArtist = "";
							actualTitle = "";
							showSlider = false;
							if (nowPlayingImage.length > 0) nowPlayingImage = "";
						}
						if (actualTitle.substring(0,10) == "x-sonosapi") {
							actualTitle = "";
						}

						playbackState = response['playbackState'];
						var playMode = response['playMode'] || {};
						var shuffleIsOn = !!playMode['shuffle'];
						shuffleButtonVisible = shuffleIsOn;
						shuffleOnButtonVisible = !shuffleIsOn;
						pauseButtonVisible = (playbackState == "PLAYING");
						playButtonVisible = !pauseButtonVisible;
						if (pauseButtonVisible) {
							sonosTrackTimer.start()
						} else {
							sonosTrackTimer.stop()
						}
					} catch(e) {
						console.log("sonos: error parsing state: " + e);
					}
				}
			}
		}
		xmlhttp.open("GET", sonosUrl("state"), true);
		xmlhttp.send();
	}

	function addTrackTimer() {
		trackElapsedTime = trackElapsedTime + 1;
		if (trackElapsedTime > trackDuration) trackElapsedTime = trackDuration;
		if (mediaScreen && trackDuration > 0) {
			mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);
		}
	}

	Timer {
		id: startupTokenTimer
		interval: 15000       // wait 15 s for network to be ready after boot
		triggeredOnStart: false
		running: false
		repeat: false
		onTriggered: refreshSpotifyAccessToken()
	}

	Timer {
		id: tokenRefreshTimer
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: refreshSpotifyAccessToken()
	}

	Timer {
		id: sonosPlayInfoTimer
		interval: 5000
		triggeredOnStart: true
		running: true
		repeat: true
		onTriggered: readSonosState()
	}

	Timer {
		id: sonosTrackTimer
		interval: 1000
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: addTrackTimer()
	}
}
//created by Harmen Bartelink, further enhanced by Toonz
