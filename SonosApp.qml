//
// Sonos v3.2 by Harmen Bartelink
// Further enhanced by Toonz after Harmen stopped developing
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
	property url spotifyMusicSearchScreenUrl : "SpotifyMusicSearchScreen.qml"
	property url tileUrl : "SonosTile.qml"
	property url tileUrlControl : "SonosMiniControlTile.qml"
	property url thumbnailIcon: "qrc:/tsc/SonosThumb.png"
	property SpotifyLoginScreen spotifyLoginScreen
	property SpotifyMusicSearchScreen spotifyMusicSearchScreen
	property MenuScreen menuScreen
	property MediaScreen mediaScreen
	property MessageScreen messageScreen
	property MediaSelectZone mediaSelectZone
	property FavoritesScreen favoritesScreen

	property SystrayIcon mediaTray
	property bool showSonosIcon : true
	property bool playFootballScores : true
	property string playbackState
	property string timeStr
	property string dateStr
	property variant playlists : []
	property variant playlistsURI : []
	property variant favourites : []
	property variant queue : []
	property variant sonoslist : []

	property string spotifyStatus : "toBeConfigured"
	property string spotifyRefreshToken : ""
	property string spotifyDisplayName : ""
	property variant spotifyPlaylists : []      // [{name, uri}]

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
			"spotifyClientSecret" : "",
			"spotifyRefreshToken" : "",
			"spotifyDisplayName" : ""
		}

	property variant spotifyToken : {
			"spotifyClientId" : "",
			"spotifyClientSecret" : "",
			"access_token" : ""
		}

	property variant messageTextArray : ["Hallo","Hallo daar, het eten staat klaar"]
	property string messageSonosName : "Alle"
	property int messageVolume : 20
	property string messageText
	property int trackDuration
	property int trackElapsedTime
	property bool showSlider : false
	property bool showSliderTime : false

	property string connectionPath

	FileIO {
		id: sonosSettingsFile
		source: "file:///mnt/data/tsc/sonos.userSettings.json"
 	}

	QtObject {
		id: p
		property url favoritesScreenUrl : "FavoritesScreen.qml"
		property url mediaScreenUrl : "MediaScreen.qml"
	}

	function init() {
		registry.registerWidget("systrayIcon", trayUrl, this, "mediaTray");
		registry.registerWidget("screen", p.mediaScreenUrl, this, "mediaScreen");
		registry.registerWidget("screen", p.favoritesScreenUrl, this, "favoritesScreen");
		registry.registerWidget("screen", menuScreenUrl, this, "menuScreen");
		registry.registerWidget("screen", messageScreenUrl, this, "messageScreen");
		registry.registerWidget("screen", mediaSelectZoneUrl, this, "mediaSelectZone");
		registry.registerWidget("screen", spotifyLoginScreenUrl, this, "spotifyLoginScreen");
		registry.registerWidget("screen", spotifyMusicSearchScreenUrl, this, "spotifyMusicSearchScreen");
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
		var newArray = [];
		var xmlhttp = new XMLHttpRequest();
		var tmpSonosName = sonosName;
		sonosName = "";
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					sonosNameIsGroup = false;
					if (response.length > 0) {
						for (var i = 0; i < response.length; i++) {
							var tmpGroupFlag = (response[i]["members"].length > 1);
							if (tmpSonosName == response[i]["coordinator"]["roomName"]) {
								sonosName = tmpSonosName;
								sonosNameIsGroup = tmpGroupFlag;
							}
							newArray.push({name: response[i]["coordinator"]["roomName"], isGroup: tmpGroupFlag});
						}
						sonoslist = newArray;
					}
					if (sonosName.length < 1) {
						sonosName = newArray[0]['name'];
						sonosNameIsGroup = newArray[0]['isGroup'];
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
		if (showSonosIcon) {
			mediaTray.show();
		} else {
			mediaTray.hide();
		}
	}

	function saveplayScores(text) {
		playFootballScores = (text == "Yes");
   		saveSettings();
	}

	function saveSettings() {
		var tmpTrayIcon = showSonosIcon ? "true" : "false";
		var tmpVoetbal = playFootballScores ? "true" : "false";

		settings["showSonosIcon"] = tmpTrayIcon;
		settings["sonosName"] = sonosName;
		settings["sonosNameVoetbalApp"] = sonosNameVoetbalApp;
		settings["path"] = connectionPath;
		settings["messageText"] = messageTextArray;
		settings["messageSonosName"] = messageSonosName;
		settings["messageVolume"] = messageVolume;
		settings["voetbalTussenstanden"] = tmpVoetbal;
		settings["spotifyStatus"] = spotifyStatus;
		settings["spotifyClientId"] = spotifyToken["spotifyClientId"];
		settings["spotifyClientSecret"] = spotifyToken["spotifyClientSecret"];
		settings["spotifyRefreshToken"] = spotifyRefreshToken;
		settings["spotifyDisplayName"] = spotifyDisplayName;

		var saveFile = new XMLHttpRequest();
		saveFile.open("PUT", "file:///mnt/data/tsc/sonos.userSettings.json");
		saveFile.send(JSON.stringify(settings));
	}

	function readSettings() {
		var settingsString = sonosSettingsFile.read();
		settings = JSON.parse(settingsString);
		if (settings['showSonosIcon']) showSonosIcon = (settings['showSonosIcon'] == "true");
		if (settings['sonosName']) sonosName = (settings['sonosName']);
		if (settings['sonosNameVoetbalApp']) sonosNameVoetbalApp = (settings['sonosNameVoetbalApp']);
		if (settings['messageVolume']) messageVolume = (settings['messageVolume']);
		if (settings['messageSonosName']) messageSonosName = (settings['messageSonosName']);
		if (settings['messageText']) messageTextArray = (settings['messageText']);
		if (settings['voetbalTussenstanden']) playFootballScores = (settings['voetbalTussenstanden'] == "true");
		if (settings['spotifyStatus']) spotifyStatus = settings['spotifyStatus'];
		if (settings['spotifyClientId']) spotifyToken["spotifyClientId"] = settings['spotifyClientId'];
		if (settings['spotifyClientSecret']) spotifyToken["spotifyClientSecret"] = settings['spotifyClientSecret'];
		if (settings['spotifyRefreshToken']) spotifyRefreshToken = settings['spotifyRefreshToken'];
		if (settings['spotifyDisplayName']) spotifyDisplayName = settings['spotifyDisplayName'];

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

		if (spotifyStatus == "configured" && spotifyRefreshToken.length > 0) {
			startupTokenTimer.start();
		}
	}

	// Build the Spotify authorization URL for the user to visit
	function buildSpotifyAuthUrl() {
		var clientId = spotifyToken["spotifyClientId"];
		var scope = "playlist-read-private%20playlist-read-collaborative";
		var redirectUri = "https%3A%2F%2Fexample.com";
		return "https://accounts.spotify.com/authorize?client_id=" + clientId +
			"&response_type=code" +
			"&redirect_uri=" + redirectUri +
			"&scope=" + scope;
	}

	// Exchange authorization code for access + refresh tokens
	function exchangeCodeForToken(code) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					spotifyToken["access_token"] = response["access_token"];
					spotifyRefreshToken = response["refresh_token"];
					spotifyStatus = "configured";
					saveSettings();
					fetchSpotifyUserProfile();
					fetchSpotifyPlaylists();
					tokenRefreshTimer.stop();
					tokenRefreshTimer.interval = 3300000;
					tokenRefreshTimer.start();
				} else {
					spotifyStatus = "error";
				}
			}
		}
		var body = "grant_type=authorization_code" +
			"&code=" + code +
			"&redirect_uri=https%3A%2F%2Fexample.com";
		xmlhttp.open("POST", "https://accounts.spotify.com/api/token");
		xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		xmlhttp.setRequestHeader("Authorization", "Basic " + customBtoa(spotifyToken["spotifyClientId"] + ":" + spotifyToken["spotifyClientSecret"]));
		xmlhttp.send(body);
	}

	// Refresh the access token using the stored refresh token
	function refreshSpotifyAccessToken() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					spotifyToken["access_token"] = response["access_token"];
					if (response["refresh_token"]) {
						spotifyRefreshToken = response["refresh_token"];
						saveSettings();
					}
					fetchSpotifyPlaylists();
					tokenRefreshTimer.stop();
					tokenRefreshTimer.interval = 3300000;
					tokenRefreshTimer.start();
				} else if (xmlhttp.status == 400 || xmlhttp.status == 401) {
					// Definitively invalid token — require re-login
					spotifyStatus = "toBeConfigured";
					spotifyRefreshToken = "";
					saveSettings();
				}
				// Any other status (network error, timeout) — keep token, retry next timer tick
			}
		}
		var body = "grant_type=refresh_token&refresh_token=" + spotifyRefreshToken;
		xmlhttp.open("POST", "https://accounts.spotify.com/api/token");
		xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		xmlhttp.setRequestHeader("Authorization", "Basic " + customBtoa(spotifyToken["spotifyClientId"] + ":" + spotifyToken["spotifyClientSecret"]));
		xmlhttp.send(body);
	}

	// Fetch user's display name from Spotify profile
	function fetchSpotifyUserProfile() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					spotifyDisplayName = response["display_name"] || response["id"] || "";
					saveSettings();
				}
			}
		}
		xmlhttp.open("GET", "https://api.spotify.com/v1/me");
		xmlhttp.setRequestHeader("Authorization", "Bearer " + spotifyToken["access_token"]);
		xmlhttp.send();
	}

	// Fetch the user's Spotify playlists and store as [{name, uri}]
	function fetchSpotifyPlaylists() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					var result = [];
					var items = response["items"];
					for (var i = 0; i < items.length; i++) {
						if (items[i] && items[i]["name"] && items[i]["uri"]) {
							result.push({name: items[i]["name"], uri: items[i]["uri"]});
						}
					}
					spotifyPlaylists = result;
				}
			}
		}
		xmlhttp.open("GET", "https://api.spotify.com/v1/me/playlists?limit=50");
		xmlhttp.setRequestHeader("Authorization", "Bearer " + spotifyToken["access_token"]);
		xmlhttp.send();
	}

	// Disconnect Spotify — clear all tokens and reset status
	function disconnectSpotify() {
		spotifyStatus = "toBeConfigured";
		spotifyRefreshToken = "";
		spotifyDisplayName = "";
		spotifyPlaylists = [];
		spotifyToken["access_token"] = "";
		tokenRefreshTimer.stop();
		saveSettings();
	}

	function customBtoa(str) {
  		const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  		let encoded = '';
  		let i = 0;

  		while (i < str.length) {
  			const c1 = str.charCodeAt(i++);
    			const c2 = str.charCodeAt(i++);
    			const c3 = str.charCodeAt(i++);

    			const e1 = c1 >> 2;
    			const e2 = ((c1 & 3) << 4) | (c2 >> 4);
    			const e3 = ((c2 & 15) << 2) | (c3 >> 6);
    			const e4 = c3 & 63;

    			if (isNaN(c2)) {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + '==';
    			} else if (isNaN(c3)) {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + '=';
    			} else {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + chars.charAt(e4);
    			}
  		}

  		return encoded;
	}

	function readSonosState() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (response['currentTrack']['type'] == "track"){
						showSlider = true;
						showSliderTime = true;
						actualArtist = "";
						actualTitle = "";
						if (response['currentTrack']['title']) actualTitle = response['currentTrack']['title'];
						if (response['currentTrack']['artist']) actualArtist = response['currentTrack']['artist'];
						if (response['currentTrack']['duration']) trackDuration = response['currentTrack']['duration'];
						if (response['elapsedTime']) {
							if (!mediaScreen.positionIndicatorDragActive) {
								trackElapsedTime = response['elapsedTime'];
								mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);
							}
						}
						if ('absoluteAlbumArtUri' in response['currentTrack']) {
							var tmpNowPlayingImage = response['currentTrack']['absoluteAlbumArtUri'].replace("https://", "http://");
						} else {
							var tmpNowPlayingImage = "";
						}
						if (tmpNowPlayingImage !== nowPlayingImage) {
							nowPlayingImage = tmpNowPlayingImage;
						}
					}
					if (response['currentTrack']['type'] == "radio"){
						showSlider = false;
						showSliderTime = false;
						actualArtist = response['currentTrack']['stationName'];
						actualTitle = "";
						if (response['playbackState'] == "PLAYING") {
							actualTitle = response['currentTrack']['title'];
						}
						if ('absoluteAlbumArtUri' in response['currentTrack']) {
							var tmpNowPlayingImage = response['currentTrack']['absoluteAlbumArtUri'].replace("https://", "http://");
						} else {
							var tmpNowPlayingImage = "";
						}
						if (tmpNowPlayingImage !== nowPlayingImage) {
							nowPlayingImage = tmpNowPlayingImage;
						}
					}
					if (actualTitle.substring(0,10) == "x-sonosapi") {
						actualTitle = "";
					}

					playbackState = response['playbackState'];
					shuffleButtonVisible = response['playMode']['shuffle'];
					shuffleOnButtonVisible = !shuffleButtonVisible;
					pauseButtonVisible = (playbackState == "PLAYING");
					playButtonVisible = !pauseButtonVisible;
					if (pauseButtonVisible) {
						sonosTrackTimer.start()
					} else {
						sonosTrackTimer.stop()
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+connectionPath+"/"+sonosName+"/state");
		xmlhttp.send();
	}

	function simpleSynchronous(request) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("GET", request, true);
		xmlhttp.timeout = 1500;
		xmlhttp.send();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					if (typeof(functie) !== 'undefined') {
						functie(parameter);
					}
				}
			}
		}
	}

	function addTrackTimer() {
		trackElapsedTime = trackElapsedTime + 1;
		if (trackElapsedTime > trackDuration) trackElapsedTime = trackDuration;
		mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);
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
