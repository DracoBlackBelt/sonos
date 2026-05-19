import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: favoritesScreen
	screenTitleIconUrl: "qrc:/tsc/Sonos_Favorites.png";
	hasHomeButton: false

	property int counterFav
	property int counterList
	property string tempId
	property string lineinUrl
	property string stationName
	
	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}

	onCustomButtonClicked: {
		if (app.spotifyStatus == "configured") {
			if (app.spotifyMusicSearchScreen) app.spotifyMusicSearchScreen.show();
		} else {
			if (app.messageScreen) app.messageScreen.show();
		}
	}
	

	onShown: {
		if (app.spotifyStatus == "configured") {
			addCustomTopRightButton("Zoek Muziek");
		} else {
			addCustomTopRightButton("Audiobericht");
		}
		screenStateController.screenColorDimmedIsReachable = false;
		pageThrobber.visible = true;
		updateFavoriteslist();
		updateLinein();
		stationNameCheck();
		updatePlaylists();
	}
	
	function playlistHeaderText() {
		return app.spotifyStatus == "configured" ? "Spotify playlists" : "Sonos playlists"
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
	
	//this text shows the counter above the scrollable list.
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

	Text {
		id: playlistHeaderLabel
		text: app.spotifyStatus == "configured" ? "Spotify playlists" : "Sonos playlists"
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		wrapMode: Text.WordWrap
		anchors {
			top: playlistScrollableSimpleList.top
			topMargin: isNxt ? -35 : -28
			left: playlistScrollableSimpleList.left
		}
		width: isNxt ? 450 : 360
	}

	
	//the function "updateLinein" is creating lineinURL which is needed to change the source to Line In (input device for sonos Playbar)
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
	
	//just refreshing manual the scrollable list.
	IconButton {
		id: refreshButton
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.rightMargin: isNxt ? 80 : 64
		anchors.topMargin: isNxt ? 20 : 16
		iconSource: "qrc:/tsc/refresh.png"
		onClicked: {
			updateFavoriteslist();
			updatePlaylists();
		}
	}
	
	//Property's for the scrollable list it self.
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


	//This is the delegate of the scrollable list which have the input of the function "updateFavoriteslist"
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

	
	//both functions below are required for the scrollable list
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
	
	//Property's for the scrollable list it self.

	ScrollableSimpleList {
		id: playlistScrollableSimpleList
		width: isNxt ? 450 : 360
		height: isNxt ? 420 : 336
		x: isNxt ? 510 : 425
		itemsPerPage: 7
		delegate: playlistDelegate
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
					if (app.spotifyStatus == "configured") {
						simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/spotify/now/"+app.playlistsURI[item]);
					} else {
						simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/playlist/"+app.playlists[item]['name']);
					}
				}
			}
		}
	}

	
	//Fill the file: FavoriteslistItemsJS with only the item "Name" and also manage a little bit the scrollable list (with refreshing it). This has also the counter function.
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
		if (app.spotifyStatus == "configured") {
			// Use already-fetched Spotify playlists from app state
			playlistScrollableSimpleList.removeAll();
			var spotList = app.spotifyPlaylists;
			if (spotList.length > 0) {
				var tmpplaylists = [];
				var tmpplaylistsURI = [];
				for (var i = 0; i < spotList.length; i++) {
					tmpplaylists.push({"name": spotList[i]["name"]});
					tmpplaylistsURI.push(spotList[i]["uri"]);
					playlistScrollableSimpleList.addDevice(i);
				}
				app.playlists = tmpplaylists;
				app.playlistsURI = tmpplaylistsURI;
				playlistScrollableSimpleList.refreshView();
				if (playlistScrollableSimpleList.currentPage == -1) {
					playlistScrollableSimpleList.scrollToPage(0);
				}
			}
			pageThrobber.visible = false;
			counterList = spotList.length;
		} else {
			// Show Sonos playlists
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
						counterList = response.length;
					}
				}
			}
			xmlhttp.open("GET", "http://"+app.connectionPath+"/playlists");
			xmlhttp.send();
		}
	}
	
	//if the station name is equal to the now playing it will be visible in the scrollable list.
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
	
	//Linein URL is important to have the possibility for changing the source to line in (like your TV or something which is plugged in to your playbar)
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
