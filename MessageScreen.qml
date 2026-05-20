import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: mediaSelectZoneScreen
	screenTitle: "Audioberichten"

	property bool waitForMessageCompletion : false

	Component.onCompleted: {   //get automatic updates from your favourite football teams (via the voetbal app)
		try{
			tscsignals.tscSignal.connect(playMessage);
		} catch(e) {
		}
	}

	function playMessage(appName, appArguments) {

		if ((appName == "sonos") && app.playFootballScores) {	
			var xmlhttp = new XMLHttpRequest();
			xmlhttp.timeout = 5000;
			xmlhttp.open("GET", "http://"+app.connectionPath+"/"+encodeURIComponent(app.sonosNameVoetbalApp)+"/say/" + encodeURIComponent(appArguments) + "/nl-nl/" + app.messageVolume);
			xmlhttp.send();
		}
	}

	onShown: {
		saveVolumeLabel.inputText = app.messageVolume;
		updateZones();
		fillEffectsList();
	}

	function fillEffectsList() {
		// fill favourites list
		favouritesScrollableSimpleList.removeAll();
		for (var i = 0; i < app.messageTextArray.length; i++) {
			favouritesScrollableSimpleList.addDevice(app.messageTextArray[i]);
		}
		favouritesScrollableSimpleList.refreshView();
	}

	function updateZones() {

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.timeout = 5000;
		xmlhttp.onerror = function() { console.log("sonos: MessageScreen updateZones network error"); }
		xmlhttp.ontimeout = function() { console.log("sonos: MessageScreen updateZones timeout"); }
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						if (response.length > 0) {
							zoneNameModel.clear();
							zoneNameModel.append({zoneName: "Alle"});
							for (var i = 0; i < response.length; i++) {
								zoneNameModel.append({zoneName: response[i]["coordinator"]["roomName"]});
							}
						}
					} catch(e) {
						console.log("sonos: error parsing zones in MessageScreen: " + e);
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}

	function removeText(item) {
		var i = app.messageTextArray.indexOf(item);
		if (i > -1) {
  			app.messageTextArray.splice(i, 1);
		}
		app.saveSettings();
		fillEffectsList();
	}

	function saveText(text) {
		if (text) {
			saveTextNameLabel.inputText = text;
			app.messageTextArray.push(text);
			app.saveSettings();
		}
	}

	function saveVolume(text) {

		if (text) {
			app.messageVolume = text;
			saveVolumeLabel.inputText = app.messageVolume;
			app.saveSettings();
		}
	}


	function validateVolume(text, isFinalString) {
		if (isFinalString) {
			if ((parseInt(text) > 19) && (parseInt(text) < 101))
				return null;
			else
				return {title: "Ongeldig volume", content: "Voer een getal in tussen 20 en 100"};
		}
		return null;
	}

	Text {
		id: txtBox

		text: "1. Selekteer een zone:"
		height: isNxt ? 35 : 28
		font.pixelSize: isNxt ? 25 : 20
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.top: parent.top
		anchors.topMargin : 10
		anchors.left: parent.left
		anchors.leftMargin : isNxt ? 25 : 20
	}

	ControlGroup {
		id: zoneGroup
		exclusive: false
	}

	GridView {
		id: zoneGridView

		model: zoneNameModel
		delegate: MessageScreenDelegate {}

		interactive: false
		flow: GridView.TopToBottom
		cellWidth: isNxt ? 320 : 250
		cellHeight: isNxt ? 50 : 40

		anchors {
			fill: parent
			top: txtBox.bottom
			left: txtBox.left
			topMargin: isNxt ? 50 : 40
		}
	}

	EditTextLabel4421 {
		id: saveTextNameLabel
		width: favouritesScrollableSimpleList.width
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 200 : 160
		leftText: "Nieuwe Tekst:"
		anchors {
			left: txtBox.left
			leftMargin: isNxt ? 375 : 300
			top: txtBox.top
			topMargin: isNxt ? 40 : 32

		}

		onClicked: {
			qkeyboard.open("Naam favouriet:", saveTextNameLabel.inputText, saveText);
		}
	}

	Text {
		id: txtBox2

		text: "2. Kies volume audiobericht:"
		height: isNxt ? 35 : 28
		font.pixelSize: isNxt ? 25 : 20
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.bottom: saveVolumeLabel.top
		anchors.left: saveVolumeLabel.left
	}

	Text {
		id: txtBox3

		text: "3. Kies bericht om af te spelen:"
		height: isNxt ? 35 : 28
		font.pixelSize: isNxt ? 25 : 20
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.bottom: txtBox.bottom
		anchors.left: favouritesScrollableSimpleList.left
	}

	EditTextLabel4421 {
		id: saveVolumeLabel
		width: isNxt ? 200 : 160
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 125 : 100
		leftText: "Volume:"
		anchors {
			left: txtBox.left
			bottom: favouritesScrollableSimpleList.bottom
		}

		onClicked: {
			qkeyboard.open("Volume (20 - 100)", saveVolumeLabel.inputText, saveVolume, validateVolume);
		}
	}

	ListModel {
		id: zoneNameModel
	}

	// favourites Message list

	//this is the delegate of the saved messages
	Component {
		id: favouritesDelegate
		//make it clickable
		Item {
			width: isNxt ? 500 : 400
			height: isNxt ? 50 : 40		
			visible: (waitForMessageCompletion == false)


			//name and number showed in the playlist
			
			StandardButton {
				id: listItemText

				text: item
				width: isNxt ? parent.width - 50 : parent.width - 40
				anchors {
					top: parent.top
					left: parent.left
					topMargin: 10
				}
				onClicked: {
					waitForMessageCompletion = true;
					var xmlhttp = new XMLHttpRequest();
					xmlhttp.timeout = 10000;
					xmlhttp.onerror = function() {
						waitForMessageCompletion = false;
						qdialog.showDialog(qdialog.SizeSmall, "Sonos mededeling", "Netwerkfout bij versturen bericht", "Sluiten");
					}
					xmlhttp.ontimeout = function() {
						waitForMessageCompletion = false;
						qdialog.showDialog(qdialog.SizeSmall, "Sonos mededeling", "Time-out bij versturen bericht", "Sluiten");
					}
					if (app.messageSonosName == "Alle") {
						xmlhttp.open("GET", "http://"+app.connectionPath+"/sayall/" + encodeURIComponent(item) + "/nl-nl/" + app.messageVolume);
					} else {
						xmlhttp.open("GET", "http://"+app.connectionPath+"/"+encodeURIComponent(app.messageSonosName)+"/say/" + encodeURIComponent(item) + "/nl-nl/" + app.messageVolume);
					}
					xmlhttp.onreadystatechange=function() {
						if (xmlhttp.readyState == 4) {
							if (xmlhttp.status == 200) {
								try {
									var messageResponse = "Fout in versturen bericht";
									var response = JSON.parse(xmlhttp.responseText);
									if (response['status']) {
										if (response['status'] == "success") {
											messageResponse = "Bericht succesvol afgespeeld";
										}
									}
									qdialog.showDialog(qdialog.SizeSmall, "Sonos mededeling", messageResponse, "Sluiten");
								} catch(e) {
									console.log("sonos: error parsing message response: " + e);
									qdialog.showDialog(qdialog.SizeSmall, "Sonos mededeling", "Ongeldig antwoord van server", "Sluiten");
								}
								waitForMessageCompletion = false;
							} else {
								waitForMessageCompletion = false;
							}
						}
					}
					xmlhttp.send();
				}
			}

			IconButton {
				id: deleteIcon
				width: 40
				iconSource: "qrc:/tsc/icon_delete.png"

				anchors {
					left: listItemText.right
					leftMargin: 10
					top: listItemText.top
				}

				bottomClickMargin: 3
				onClicked: removeText(item)
			}
		}
	}
	
	//property's of the scrollable list
	ScrollableSimpleList {
		id: favouritesScrollableSimpleList
		width: isNxt ? 600 : 480
		height: isNxt ? 375 : 300
		itemsPerPage: 6
		delegate: favouritesDelegate
		anchors.top: saveTextNameLabel.bottom
		anchors.right: saveTextNameLabel.right
		anchors.topMargin: isNxt ? 25 : 20
	}
}