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
								actualArtist = "?";
								if (response[i]["coordinator"]["state"]['currentTrack']['type'] == "track"){
									if (response[i]["coordinator"]["state"]['currentTrack']['artist']) actualArtist = response[i]["coordinator"]["state"]['currentTrack']['artist'];
								}
								if (response[i]["coordinator"]["state"]['currentTrack']['type'] == "radio"){
									if (response[i]["coordinator"]["state"]['currentTrack']['stationName']) actualArtist = response[i]["coordinator"]["state"]['currentTrack']['stationName'];
								}
								if (response[i]["members"].length > 1) {
									tmpIsGroup = "yes"
								} else {
									tmpIsGroup = "no"
								}
								console.log("SelectZone:" + i + "-" + "zoneName:" + response[i]["coordinator"]["roomName"] + ",playbackState:" + response[i]["coordinator"]["state"]["playbackState"] + ", volume:" + response[i]["coordinator"]["groupState"]["volume"] + ", artist:" + actualArtist + ", isGroup:" + tmpIsGroup);
								zoneNameModel.append({zoneName: response[i]["coordinator"]["roomName"], playbackState: response[i]["coordinator"]["state"]["playbackState"], volume: response[i]["coordinator"]["groupState"]["volume"], artist: actualArtist, isGroup: tmpIsGroup});
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
			fill: parent
			top: txtBox.bottom
			left: txtBox.left
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