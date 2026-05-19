import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: favoritesScreen
	screenTitleIconUrl: "qrc:/tsc/Sonos_Favorites.png";
	hasHomeButton: false

	property int counterFav
	property string tempId
	property string lineinUrl
	property string stationName
	property variant rightPanelItems : []
	property bool searchActive : false

	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}

	onCustomButtonClicked: {
		if (app.messageScreen) app.messageScreen.show();
	}

	onShown: {
		addCustomTopRightButton("Audiobericht");
		screenStateController.screenColorDimmedIsReachable = false;
		pageThrobber.visible = true;
		updateFavoriteslist();
		updateLinein();
		stationNameCheck();
		if (app.spotifyStatus == "configured") {
			loadRecents();
		} else {
			updatePlaylists();
		}
	}

	//Required to use the Sonos HTTP API and to start every request in the functions.
	function simpleSynchronous(request) {
		pageThrobber.visible = true;
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("GET", request, true);
		xmlhttp.timeout = 1500;
		xmlhttp.send();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					pageThrobber.visible = false;
					if (typeof(functie) !== 'undefined') {
						functie(parameter);
					}
				}
			}
		}
	}

	//if the connection is not available or is still loading a page throbber will be visible in the scrollable list.
	Throbber {
		id: pageThrobber
		visible: true
		z: isNxt ? 25 : 20
		anchors {
			horizontalCenter: parent.horizontalCenter
			verticalCenter: parent.verticalCenter
		}
	}

	Text {
		id: chooseText
		text: "Sonos favorieten:"
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		wrapMode: Text.WordWrap
		anchors {
			top: favouritesScrollableSimpleList.top
			topMargin: isNxt ? -35 : -28
			left: favouritesScrollableSimpleList.left
		}
		width: 450
	}

	// Right panel header: shown only when Spotify is NOT configured (Sonos playlists)
	Text {
		id: playlistHeaderLabel
		text: "Sonos playlists"
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		wrapMode: Text.WordWrap
		visible: app.spotifyStatus != "configured"
		anchors {
			top: playlistScrollableSimpleList.top
			topMargin: isNxt ? -35 : -28
			left: playlistScrollableSimpleList.left
		}
		width: isNxt ? 450 : 360
	}

	// Spotify panel header: shown when Spotify is configured
	Text {
		id: spotifyPanelHeader
		text: "Spotify zoeken:"
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		wrapMode: Text.WordWrap
		visible: app.spotifyStatus == "configured"
		anchors {
			top: spotifySearchInput.top
			topMargin: isNxt ? -35 : -28
			left: spotifySearchInput.left
		}
		width: isNxt ? 450 : 360
	}

	IconButton {
		id: inputButton
		anchors.top: parent.top
		anchors.right: refreshButton.left
		anchors.rightMargin: 10
		anchors.topMargin: isNxt ? 20 : 16
		iconSource: "qrc:/tsc/input.png"
		onClicked: {
			simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/setavtransporturi/x-sonos-htastream:"+lineinUrl+":spdif")
		}
	}

	IconButton {
		id: refreshButton
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.rightMargin: isNxt ? 80 : 64
		anchors.topMargin: isNxt ? 20 : 16
		iconSource: "qrc:/tsc/refresh.png"
		onClicked: {
			updateFavoriteslist();
			if (app.spotifyStatus == "configured") {
				loadRecents();
			} else {
				updatePlaylists();
			}
		}
	}

	// Left column: Sonos favorites
	ScrollableSimpleList {
		id: favouritesScrollableSimpleList
		width: isNxt ? 450 : 360
		height: isNxt ? 420 : 336
		x: isNxt ? 30 : 25
		itemsPerPage: 7
		delegate: brandListDelegate
		anchors {
			top: refreshButton.bottom
			topMargin: isNxt ? 12 : 10
		}

		Throbber {
			id: throbber
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
				verticalCenter: parent.verticalCenter
			}
		}
	}

	Component {
		id: brandListDelegate
		Item {
			width: isNxt ? 450 : 360
			height: isNxt ? 50 : 40

			StandardButton {
				id: listItemButton
				radius: 5
				text: app.favourites[item]['name']
				width: isNxt ? 350 : 280
				anchors {
					top: parent.top
				}

				onClicked: {
					tempId = app.favourites[item]["name"];
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/favorite/"+tempId);
					hide();
				}
			}
		}
	}

	// Right column: Sonos playlists (only when Spotify not configured)
	ScrollableSimpleList {
		id: playlistScrollableSimpleList
		width: isNxt ? 450 : 360
		height: isNxt ? 420 : 336
		x: isNxt ? 510 : 425
		itemsPerPage: 7
		delegate: playlistDelegate
		visible: app.spotifyStatus != "configured"
		anchors {
			top: refreshButton.bottom
			topMargin: isNxt ? 12 : 10
		}
		Throbber {
			id: throbberPL
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
				verticalCenter: parent.verticalCenter
			}
		}
	}

	Component {
		id: playlistDelegate
		Item {
			width: isNxt ? 450 : 360
			height: isNxt ? 50 : 40
			StandardButton {
				id: playlistButton
				radius: 5
				text: app.playlists[item]['name']
				width: isNxt ? 350 : 280
				anchors {
					top: parent.top
				}
				onClicked: {
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/playlist/"+app.playlists[item]['name']);
				}
			}
		}
	}

	// Right column: Spotify search input (only when Spotify configured)
	EditTextLabel4421 {
		id: spotifySearchInput
		width: isNxt ? 450 : 360
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 100 : 80
		leftText: "Zoeken:"
		x: isNxt ? 510 : 425
		visible: app.spotifyStatus == "configured"
		anchors {
			top: refreshButton.bottom
			topMargin: isNxt ? 12 : 10
		}
		onClicked: {
			qkeyboard.open("Zoek naar muziek:", spotifySearchInput.inputText, saveSpotifySearchText)
		}
	}

	// Right column: Spotify search results / recents list
	ScrollableSimpleList {
		id: rightPanelList
		width: isNxt ? 450 : 360
		height: isNxt ? 360 : 288
		x: isNxt ? 510 : 425
		itemsPerPage: 6
		delegate: rightPanelDelegate
		visible: app.spotifyStatus == "configured"
		anchors {
			top: spotifySearchInput.bottom
			topMargin: isNxt ? 8 : 6
		}
		Throbber {
			id: throbberSearch
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
				verticalCenter: parent.verticalCenter
			}
		}
	}

	Component {
		id: rightPanelDelegate
		Item {
			width: isNxt ? 450 : 360
			height: isNxt ? 50 : 40
			StandardButton {
				radius: 5
				text: rightPanelItems[item]['name']
				width: isNxt ? 350 : 280
				anchors.top: parent.top
				onClicked: {
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/spotify/now/" + rightPanelItems[item]['uri']);
					app.addToRecentlyPlayed(rightPanelItems[item]['name'], rightPanelItems[item]['uri']);
					hide();
				}
			}
		}
	}

	function pad(n, width) {
		n = n + '';
		return n.length >= width ? n : new Array(width - n.length + 1).join('0') + n;
	}

	function objToString (obj) {
		var str = '';
		for (var p in obj) {
			if (obj.hasOwnProperty(p)) {
				str += p + '::' + obj[p] + '\n';
			}
		}
		return str;
	}

	function updateFavoriteslist() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					favouritesScrollableSimpleList.removeAll();
					stationNameCheck();
					if (response.length > 0) {
						var tmpfavourites = [];
						for (var i = 0; i < response.length; i++) {
							tmpfavourites.push({"name": response[i]});
							favouritesScrollableSimpleList.addDevice(i);
						}
						app.favourites = tmpfavourites;
						favouritesScrollableSimpleList.refreshView();
						if (favouritesScrollableSimpleList.currentPage == -1) {
							favouritesScrollableSimpleList.scrollToPage(0);
						}
					}
					counterFav = response.length;
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/favorites");
		xmlhttp.send();
	}

	function updatePlaylists() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					playlistScrollableSimpleList.removeAll();
					if (response.length > 0) {
						var tmpplaylists = [];
						for (var i = 0; i < response.length; i++) {
							tmpplaylists.push({"name": response[i]});
							playlistScrollableSimpleList.addDevice(i);
						}
						app.playlists = tmpplaylists;
						playlistScrollableSimpleList.refreshView();
						if (playlistScrollableSimpleList.currentPage == -1) {
							playlistScrollableSimpleList.scrollToPage(0);
						}
					}
					pageThrobber.visible = false;
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/playlists");
		xmlhttp.send();
	}

	function loadRecents() {
		searchActive = false;
		spotifySearchInput.inputText = "";
		populateRightPanelList(app.recentlyPlayed);
		pageThrobber.visible = false;
	}

	function populateRightPanelList(items) {
		rightPanelList.removeAll();
		rightPanelItems = items;
		for (var i = 0; i < items.length; i++) {
			rightPanelList.addDevice(i);
		}
		rightPanelList.refreshView();
		if (items.length > 0 && rightPanelList.currentPage == -1) {
			rightPanelList.scrollToPage(0);
		}
	}

	function saveSpotifySearchText(text) {
		spotifySearchInput.inputText = text;
		if (text && text.length > 0) {
			searchSpotify(text);
		} else {
			loadRecents();
		}
	}

	function searchSpotify(query) {
		searchActive = true;
		pageThrobber.visible = true;
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = function() {
			if (xmlhttp.readyState == 4) {
				pageThrobber.visible = false;
				if (xmlhttp.status == 200) {
					var results = JSON.parse(xmlhttp.responseText);
					var tmpItems = [];
					if (results["tracks"] && results["tracks"]["items"]) {
						var tracks = results["tracks"]["items"];
						for (var i = 0; i < tracks.length; i++) {
							tmpItems.push({
								name: tracks[i]["name"] + " - " + tracks[i]["artists"][0]["name"],
								uri: tracks[i]["uri"]
							});
						}
					}
					if (results["albums"] && results["albums"]["items"]) {
						var albums = results["albums"]["items"];
						for (var j = 0; j < albums.length; j++) {
							tmpItems.push({
								name: "[Album] " + albums[j]["name"] + " - " + albums[j]["artists"][0]["name"],
								uri: albums[j]["uri"]
							});
						}
					}
					populateRightPanelList(tmpItems);
				}
			}
		}
		xmlhttp.open("GET", "https://api.spotify.com/v1/search?q=" + query + "&type=track,album&limit=10");
		xmlhttp.setRequestHeader("Authorization", "Bearer " + app.spotifyToken["access_token"]);
		xmlhttp.send();
	}

	function stationNameCheck() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					stationName = response['currentTrack']['stationName'];
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/"+app.sonosName+"/state");
		xmlhttp.send();
	}

	function updateLinein() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					for (var i = 0; i < response.length; i++) {
						if (response[i]['coordinator']['roomName'] == app.sonosName) {
							lineinUrl = response[i]['coordinator']['coordinator'];
						}
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}
}

//created by Harmen Bartelink
