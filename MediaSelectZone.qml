import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: mediaSelectZoneScreen
	screenTitle: "Sonos Zone Overzicht"

	onShown: {
		zoneTimer.start();
		updateZones();
	}

	onHidden: {
		zoneTimer.stop();
	}

	function updateZones() {

		var xmlhttp = new XMLHttpRequest();
		var actualArtist = "";
		var tmpIsGroup = "";
		xmlhttp.timeout = 5000;
		xmlhttp.onerror = function() { console.log("sonos: MediaSelectZone updateZones network error"); }
		xmlhttp.ontimeout = function() { console.log("sonos: MediaSelectZone updateZones timeout"); }
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					try {
						var response = JSON.parse(xmlhttp.responseText);
						if (response.length > 0) {
							zoneNameModel.clear();
							for (var i = 0; i < response.length; i++) {
								var coord = response[i]["coordinator"] || {};
								var roomName = coord["roomName"] || "";
								if (roomName.length < 1) continue;
								var state = coord["state"] || {};
								var currentTrack = state["currentTrack"] || {};
								actualArtist = "?";
								if (currentTrack["type"] == "track"){
									if (currentTrack["artist"]) actualArtist = currentTrack["artist"];
								}
								if (currentTrack["type"] == "radio"){
									if (currentTrack["stationName"]) actualArtist = currentTrack["stationName"];
								}
								var members = response[i]["members"];
								if (members && members.length > 1) {
									tmpIsGroup = "yes"
								} else {
									tmpIsGroup = "no"
								}
								var groupState = coord["groupState"] || {};
								var zoneVolume = (typeof groupState["volume"] == 'number') ? groupState["volume"] : 0;
								zoneNameModel.append({zoneName: roomName, playbackState: state["playbackState"] || "", volume: zoneVolume, artist: actualArtist, isGroup: tmpIsGroup});
							}
						}
					} catch(e) {
						console.log("sonos: error parsing zones in MediaSelectZone: " + e);
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}


	Text {
		id: txtBox

		text: "Selekteer een zone:"
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

	Text {
		id: volBox

		text: "Volume:"
		height: isNxt ? 35 : 28
		font.pixelSize: isNxt ? 25 : 20
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 100 : 80
		anchors.top: parent.top
		anchors.topMargin : 10
		anchors.right: parent.right
		anchors.rightMargin : isNxt ? 5 : 4
	}

	ControlGroup {
		id: zoneGroup
		exclusive: false
	}

	GridView {
		id: zoneGridView

		model: zoneNameModel
		delegate: MediaSelectZoneDelegate {}

		interactive: false
		flow: GridView.TopToBottom
		cellWidth: isNxt ? 320 : 250
		cellHeight: isNxt ? 50 : 40

		anchors {
			top: txtBox.bottom
			left: txtBox.left
			right: parent.right
			bottom: parent.bottom
			topMargin: isNxt ? 50 : 40
		}
	}

	ListModel {
		id: zoneNameModel
	}

	
	Timer {
		id: zoneTimer
		interval: 10000
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: updateZones()
	}

}