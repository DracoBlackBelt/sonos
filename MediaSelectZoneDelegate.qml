import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Rectangle
{
	width: isNxt ? 320 : 250
	height: isNxt ? 50 : 40
	color: colors.canvas
	property string kpiPrefix: "zoneSelectscreen"

	function friendlyName(state) {
		switch (state) {
			case "TRANSITIONING": return "Overgang";
			case "PLAYING": return "Speelt af";
			case "STOPPED": return "Gestopt";
			case "PAUSED_PLAYBACK": return "Gepauzeerd";
			default: break;
		}
		return state;
	}


	StandardButton {
		id: zoneButton
		controlGroup: zoneGroup
		width: isNxt ? 270 : 220
		height: isNxt ? 45 : 36
		radius: 5
		text: (isGroup == "yes") ? "Grp " + zoneName : zoneName
		fontPixelSize: isNxt ? 25 : 20
		x: isNxt ? 25 : 20
		onClicked: {
			if (app.zoneToSelect == "sonosName") {
				app.sonosName = zoneName;
				app.sonosNameIsGroup = (isGroup == "yes");
			}
			if (app.zoneToSelect == "sonosNameVoetbalApp") {
				app.sonosNameVoetbalApp = zoneName;
			}
			app.saveSettings();
			hide();
		}
	}

	Text {
		id: itemMuted

		text: friendlyName(playbackState)
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.left: zoneButton.right
		anchors.leftMargin : 20
		anchors.top: zoneButton.top
	}

	Text {
		id: itemArtist

		text: artist
		font.pixelSize: isNxt ? 15 : 12
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.left: zoneButton.right
		anchors.leftMargin : 20
		anchors.bottom: zoneButton.bottom
	}
	
	//volume control session start here, first you'll find the first button.
	IconButton {
		id: volumeDown
		anchors {
			left: itemMuted.right
			leftMargin: isNxt ? 15 : 12
		}

		iconSource: "qrc:/tsc/volume_down_small.png"
		onClicked: {
			if (isGroup == "yes") {
				app.apiGet(app.zoneUrl(zoneName, "groupVolume/-2"));
			} else {
				app.apiGet(app.zoneUrl(zoneName, "volume/-2"));
			}
		}
		visible: volume > 0
	}
	IconButton {
		id: prevButton
		anchors {
			left: volumeDown.right
			leftMargin: isNxt ? 15 : 12
			bottom: volumeDown.bottom
		}

		iconSource: "qrc:/tsc/left.png"
		onClicked: {
			app.apiGet(app.zoneUrl(zoneName, "previous"));
		}
	}

	IconButton {
		id: pauseButton
		anchors {
			left: prevButton.right
			leftMargin: isNxt ? 15 : 12
			bottom: prevButton.bottom
		}

		iconSource: "qrc:/tsc/pause.png"
		onClicked: {
			app.apiGet(app.zoneUrl(zoneName, "pause"));
		}
		visible: playbackState == "PLAYING"
	}
	
	IconButton {
		id: playButton
		anchors {
			left: pauseButton.right
			leftMargin: isNxt ? 15 : 12
			bottom: pauseButton.bottom
		}

		iconSource: "qrc:/tsc/play.png"
		onClicked: {
			app.apiGet(app.zoneUrl(zoneName, "play"));
			}
		visible: playbackState !== "PLAYING"
	}

	IconButton {
		id: nextButton
		anchors {
			left: playButton.right
			leftMargin: isNxt ? 15 : 12
			bottom: pauseButton.bottom
		}

		iconSource: "qrc:/tsc/right.png"
		onClicked: {
			app.apiGet(app.zoneUrl(zoneName, "next"));
		}
	}	
	
	//last in this section is the volume up button.
	IconButton {
		id: volumeUp
		anchors {
			bottom: nextButton.bottom
			left: nextButton.right
			leftMargin: isNxt ? 15 : 12
		}

		iconSource: "qrc:/tsc/volume_up_small.png"
		onClicked: {
			if (isGroup == "yes") {
				app.apiGet(app.zoneUrl(zoneName, "groupVolume/+2"));
			} else {
				app.apiGet(app.zoneUrl(zoneName, "volume/+2"));
			}
		}
		visible: volume < 100
	}

	Text {
		id: itemVolume

		text: volume + "%"
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 75 : 60
		anchors.left: volumeUp.right
		anchors.leftMargin : isNxt ? 20 : 10
		anchors.top: volumeUp.top
		anchors.topMargin : 10
	}


}
