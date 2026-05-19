import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: favoritesScreen
	screenTitle: "Zoek in Spotify";

	property int albumCount : 0
	property int trackCount : 0
	property int playlistCount : 0
	property variant searchResults : []
	property variant displayResults : []
	property bool albumSelected : false
	property bool trackSelected : false
	property bool playlistSelected : false
	
	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}

	onCustomButtonClicked: {
		if (app.messageScreen) app.messageScreen.show();
	}
	

	onShown: {
		addCustomTopRightButton("Audiobericht");	
		screenStateController.screenColorDimmedIsReachable = false;
		pageThrobber.visible = false;
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

	function saveSearchTextLabel(text) {

		if (text) {
			searchTextLabel.inputText = text;
			searchMusic();
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

		text: "Zoek op naam artiest/album/titel van de track:"
		font.pixelSize: isNxt ? 20 : 16

		font.family: qfont.regular.name
		font.bold: true

		wrapMode: Text.WordWrap
		anchors {
			top: parent.top
			topMargin: isNxt ? 20 : 16
			left: parent.left
			leftMargin: isNxt ? 20 : 16		}
	}

	EditTextLabel4421 {
		id: searchTextLabel
		width: isNxt ? 550 : 440
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 150 : 120
		leftText: "Zoeken op:"
		x: isNxt ? 38 : 30
		y: 10

		anchors {
			top: chooseText.bottom
			left: chooseText.left
		}

		onClicked: {
			qkeyboard.open("Zoek naar muziek:", searchTextLabel.inputText, saveSearchTextLabel)
		}
	}


	StandardButton {
		id: searchResultsAlbums
		width: isNxt ? 175 : 140
		radius: 5
		text: "Albums (" + albumCount + ")"
		fontPixelSize: isNxt ? 20 : 16
		color: colors.background
		anchors {
			top: searchTextLabel.bottom
			topMargin: isNxt ? 30 : 24
			left: searchTextLabel.left
		}
		visible: (albumCount  > 0)

		onClicked: {
			var tmpResults = [];
			searchResultsSimpleList.removeAll();

			for (var i = 0; i < albumCount ; i++) {
				tmpResults.push({"name": searchResults["albums"]["items"][i]["name"] + " (" + searchResults["albums"]["items"][i]["artists"][0]["name"] + ")" , "uri":searchResults["albums"]["items"][i]["uri"]}); 
				searchResultsSimpleList.addDevice(i);
			}
			displayResults = tmpResults;
			searchResultsSimpleList.refreshView();
			searchResultsSimpleList.scrollToPage(0);
			trackSelected = false
			albumSelected = true
			playlistSelected = false
		}
	}

	Text {
		id: albumSelectedText

		text: "-->"
		font.pixelSize: isNxt ? 30 : 24

		font.family: qfont.regular.name
		font.bold: true
		visible: albumSelected
		wrapMode: Text.WordWrap
		anchors {
			top: searchResultsAlbums.top
			left: searchResultsAlbums.right
			leftMargin : isNxt ? 15 : 12
		}
	}

	StandardButton {
		id: searchResultsTracks
		width: isNxt ? 175 : 140
		radius: 5
		text: "Tracks (" + trackCount + ")"
		fontPixelSize: isNxt ? 20 : 16
		color: colors.background
		anchors {
			top: searchResultsAlbums.bottom
			topMargin: isNxt ? 20 : 16
			left: searchResultsAlbums.left
		}
		visible: (trackCount  > 0)

		onClicked: {
			var tmpResults = [];
			searchResultsSimpleList.removeAll();

			for (var i = 0; i < trackCount ; i++) {
				tmpResults.push({"name": searchResults["tracks"]["items"][i]["name"] + " (" + searchResults["tracks"]["items"][i]["artists"][0]["name"] + ")" , "uri":searchResults["tracks"]["items"][i]["uri"]}); 
				searchResultsSimpleList.addDevice(i);
			}
			displayResults = tmpResults;
			searchResultsSimpleList.refreshView();
			searchResultsSimpleList.scrollToPage(0);
			trackSelected = true
			albumSelected = false
			playlistSelected = false

		}
	}

	Text {
		id: trackSelectedText

		text: "-->"
		font.pixelSize: isNxt ? 30 : 24
		font.family: qfont.regular.name
		font.bold: true
		visible: trackSelected
		wrapMode: Text.WordWrap
		anchors {
			top: searchResultsTracks.top
			left: searchResultsTracks.right
			leftMargin : isNxt ? 15 : 12
		}
	}

	StandardButton {
		id: searchResultsPlaylists
		width: isNxt ? 175 : 140
		radius: 5
		text: "Playlists (" + playlistCount + ")"
		fontPixelSize: isNxt ? 20 : 16
		color: colors.background
		anchors {
			top: searchResultsTracks.bottom
			topMargin: isNxt ? 20 : 16
			left: searchResultsTracks.left
		}
		visible: (playlistCount > 0)


		onClicked: {
			var tmpResults = [];
			searchResultsSimpleList.removeAll();

			for (var i = 0; i < playlistCount ; i++) {
				tmpResults.push({"name": searchResults["playlists"]["items"][i]["name"] , "uri":searchResults["playlists"]["items"][i]["uri"]});
				searchResultsSimpleList.addDevice(i);
			}
			displayResults = tmpResults;
			searchResultsSimpleList.refreshView();
			searchResultsSimpleList.scrollToPage(0);
			trackSelected = false
			albumSelected = false
			playlistSelected = true
		}
	}

	Text {
		id: playlistSelectedText

		text: "-->"
		font.pixelSize: isNxt ? 30 : 24
		font.family: qfont.regular.name
		font.bold: true
		visible: playlistSelected
		wrapMode: Text.WordWrap
		anchors {
			top: searchResultsPlaylists.top
			left: searchResultsPlaylists.right
			leftMargin : isNxt ? 15 : 12
		}
	}

	Text {
		id: maxText

		text: "Maximaal 20 resultaten\nper categorie"
		font.pixelSize: isNxt ? 20 : 16

		font.family: qfont.regular.name
		font.bold: true
		visible: ((albumCount == 20) || (trackCount == 20) || (playlistCount == 20))

		wrapMode: Text.WordWrap
		anchors {
			top: searchResultsPlaylists.bottom
			topMargin: isNxt ? 15 : 12
			left: searchResultsPlaylists.left
		}
		width: 450
	}

	StandardButton {
		id: playAllTracks
		width: isNxt ? 175 : 140
		radius: 5
		text: "Play all tracks"
		fontPixelSize: isNxt ? 20 : 16
		color: colors.background
		anchors {
			bottom: searchResultsSimpleList.bottom
			left: searchResultsTracks.left
		}
		visible: trackSelected


		onClicked: {
			simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
			for (var i = 0; i < trackCount ; i++) {
				simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/spotify/queue/" + searchResults["tracks"]["items"][i]["uri"]);
			}
			simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/play")
			if (app.mediaScreen) app.mediaScreen.show();
		}
	}
		
	//Property's for the scrollable list it self.

	ScrollableSimpleList {
		id: searchResultsSimpleList
		width: isNxt ? 750 : 600
		height: isNxt ? 420 : 336
		itemsPerPage: 7
		delegate: serachResultsDelegate
		anchors {
			top: searchTextLabel.bottom
			topMargin: isNxt ? 15 : 12
			left: albumSelectedText.right
			leftMargin: isNxt ? 10 : 8
		}
		visible: ( (albumCount > 0) || (trackCount > 0) || (playlistCount > 0 ))
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
		id: serachResultsDelegate
		//to make the list clickable
		Item {
			width: isNxt ? 750 : 600
			height: isNxt ? 50 : 40	
			StandardButton {
				id: playlistButtom
				radius: 5
				text: displayResults[item]['name']
				width: isNxt ? 650 : 520
				anchors {
					top: parent.top
				}

				onClicked: {
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/spotify/now/" + displayResults[item]['uri']);
					if (!trackSelected) app.mediaScreen.show();
				}
			}			
		}
	}

		
	//Fill the file: FavoriteslistItemsJS with only the item "Name" and also manage a little bit the scrollable list (with refreshing it). This has also the counter function.
	function searchMusic() {

		if (app.spotifyStatus == "configured") {
			var xmlhttpSpot = new XMLHttpRequest();	
			xmlhttpSpot.onreadystatechange=function() {
				if (xmlhttpSpot.readyState == 4) {
					if (xmlhttpSpot.status == 200) {

						searchResults = JSON.parse(xmlhttpSpot.responseText);
						searchResultsSimpleList.removeAll();

							// get search results counters for albums, tracks and playlists

						trackCount = 0;
						if (searchResults["tracks"]) {
							if (searchResults["tracks"]["items"]) {
								trackCount = searchResults["tracks"]["items"].length
							}
						}

						albumCount = 0;
						if (searchResults["albums"]) {
							if (searchResults["albums"]["items"]) {
								albumCount = searchResults["albums"]["items"].length
							}
						}

						playlistCount = 0;
						if (searchResults["playlists"]) {
							if (searchResults["playlists"]["items"]) {
								playlistCount = searchResults["playlists"]["items"].length
							}
						}

							// fill displayResults with tracks

	
						if (trackCount > 0) {
							var tmpResults = [];
							for (var i = 0; i < trackCount ; i++) {
								tmpResults.push({"name": searchResults["tracks"]["items"][i]["name"] + " (" + searchResults["tracks"]["items"][i]["artists"][0]["name"] + ")" , "uri":searchResults["tracks"]["items"][i]["uri"]}); 
								searchResultsSimpleList.addDevice(i);
							}
							displayResults = tmpResults;
							searchResultsSimpleList.refreshView();
							if (searchResultsSimpleList.currentPage == -1) {
								searchResultsSimpleList.scrollToPage(0);
							}
							trackSelected = true
							albumSelected = false
							playlistSelected = false
						} 
						pageThrobber.visible = false;
					}
				}
			}
		}
		xmlhttpSpot.open("GET", "https://api.spotify.com/v1/search?q=" + searchTextLabel.inputText + "&type=track,album,playlist,artist");
               	xmlhttpSpot.setRequestHeader("Authorization", 'Bearer ' + app.spotifyToken["access_token"]);
		xmlhttpSpot.send();
	}
}


