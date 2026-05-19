import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: root
	screenTitle: qsTr("Sonos Instellingen")
	
	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}
	
	onShown: {
		showSonosIconToggle.isSwitchedOn = app.showSonosIcon;
		voetbalToggle.isSwitchedOn = app.playFootballScores;
		if (app.playFootballScores) {
			if (app.sonosNameVoetbalApp.length < 2) app.sonosNameVoetbalApp = "Klik om een zone te selekteren voor de standen";
		}
		addCustomTopRightButton("Check Connection");
		poortnummerLabel.inputText = app.poortnummer;
		ipadresLabel.inputText = app.ipadresLabel;
	}

	onCustomButtonClicked: {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (response.length > 0) {
						app.sonosName = response[0]["coordinator"]["roomName"];
						hide();
						if (response.length > 1) {
							app.mediaSelectZone.show();
						}
					} 
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}

	//Next part is to have the possibility to use the keyboard for the Hostname/IP Address field and also for the portnumber!
	QtObject {
		id: p
		property int _IP_KEYBOARD: 1
		property int _PORTNUMBER_KEYBOARD: 2
	}

	function openKeyboard(location) {
		if (location === p._PORTNUMBER_KEYBOARD) {
			qkeyboard.open(qsTr("voer hier de poort in"), poortnummerLabel.inputText, savePoortnummer);
		} else {
			if (ipadresLabel.inputText)
				qkeyboard.open(qsTr("Voer hier uw hostname of ip-adres in"), ipadresLabel.inputText, saveIpadres);
			else
				qkeyboard.open(qsTr("Voer hier uw hostname of ip-adres in"), "", saveIpadres);
		}
	}
	
	function saveIpadres(text) {
		if (text) {
			app.ipadresLabel = text;
			ipadresLabel.inputText = text;
			savepath();
		}
	}

	function savePoortnummer(text) {
		if (text) {
			app.poortnummer = text;
			poortnummerLabel.inputText = text;
			savepath();
		}
	}

	function savepath(){
		app.connectionPath = ipadresLabel.inputText + ":" + poortnummerLabel.inputText;
		app.saveSettings();
	}
	
	Column {
		id: labelContainer
		anchors {
			top: parent.top
			topMargin: 20
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 6


		Item {
			width: parent.width
			height: childrenRect.height

			Text {
				id: titleText
				anchors {
					left: parent.left
				}
				font {
					pixelSize: qfont.bodyText
					family: qfont.regular.name
				}
				wrapMode: Text.WordWrap
				text: "Configureer hier de instellingen voor Sonos-http-api server:"
			}
		}

		Item {
			width: parent.width
			height: childrenRect.height
			
			EditTextLabel4421 {
				id: ipadresLabel
				height: editipAdresButton.height
				width: isNxt ? 800 : 600
				leftText: qsTr("Hostname of ip-adres")
				leftTextAvailableWidth:isNxt ? 500 : 400

				onClicked: {
					openKeyboard(p._IP_KEYBOARD);
				}
			}
			
			IconButton {
				id: editipAdresButton
				width: 40
				anchors {
					bottom: ipadresLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"

				onClicked: {
					openKeyboard(p._IP_KEYBOARD);
				}
			}
		}

		Item {
			width: parent.width
			height: childrenRect.height

			EditTextLabel4421 {
				id: poortnummerLabel
				height: editportNumberButton.height
				width: isNxt ? 800 : 600
				leftText: qsTr("Poortnummer (default is 5005)")
				leftTextAvailableWidth:isNxt ? 500 : 400

				onClicked: {
					openKeyboard(p._PORTNUMBER_KEYBOARD);
				}
			}
			
			IconButton {
				id: editportNumberButton
				width: 40
				anchors {
					bottom: poortnummerLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"

				onClicked: {
					openKeyboard(p._PORTNUMBER_KEYBOARD);
				}
			}
		}

	}
	//here stops the first function of the keyboards!
	
		
	//Next part is to give someone the option for having a systray icon (in the right upper corner)
	Text {
		id: systrayText
		anchors {
			left: parent.left
			leftMargin: 44
			top: labelContainer.bottom
			topMargin: 20
		}
		font {
			pixelSize: qfont.bodyText
			family: qfont.regular.name
		}
		wrapMode: Text.WordWrap
		text: "Sonos icoon zichtbaar op systray?"
	}
	
		OnOffToggle {
		id: showSonosIconToggle
		height: 36
		anchors {
			left: systrayText.left
			top: systrayText.bottom
			topMargin: 5
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.saveshowSonosIcon("Yes")
			} else {
				app.saveshowSonosIcon("No")
			}
		}
	}
		
	//Next part is to allow new results from live matches of your favourite teams to be played over the Sonos speakers.

	Text {
		id: voetbalText
		anchors {
			left: parent.left
			leftMargin: 44
			top: showSonosIconToggle.bottom
			topMargin: 20
		}
		font {
			pixelSize: qfont.bodyText
			family: qfont.regular.name
		}
		wrapMode: Text.WordWrap
		text: "Voetbal tussenstanden afspelen (configureren via voetbal app)?"
	}
	
	OnOffToggle {
		id: voetbalToggle
		height: 36
		anchors {
			left: voetbalText.left
			top: voetbalText.bottom
			topMargin: 5
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.saveplayScores("Yes")
				if (app.sonosNameVoetbalApp.length < 2) app.sonosNameVoetbalApp = "Klik om een zone te selekteren voor de standen"
			} else {
				app.saveplayScores("No")
			}
		}
	}

	StandardButton {
		id: btnZone
		text: app.sonosNameVoetbalApp
		fontPixelSize: isNxt ? 25 : 20
		anchors {
			bottom: voetbalToggle.bottom
			left: voetbalToggle.right
			leftMargin: isNxt ? 25 : 20
		}
		onClicked: {
			if (app.mediaSelectZone) {
				app.zoneToSelect = "sonosNameVoetbalApp";	
				app.mediaSelectZone.show();
			}
		}
		visible: voetbalToggle.isSwitchedOn
	}
		
	// Spotify section
	StandardButton {
		id: spotifyButton
		width: isNxt ? 400 : 320
		radius: 5
		fontPixelSize: isNxt ? 25 : 20
		color: colors.background
		text: app.spotifyStatus == "configured"
			? "Spotify: " + (app.spotifyDisplayName.length > 0 ? app.spotifyDisplayName : "verbonden")
			: "Verbind met Spotify"
		anchors {
			top: btnZone.bottom
			topMargin: 20
			left: voetbalText.left
		}
		onClicked: {
			if (app.spotifyLoginScreen)
				app.spotifyLoginScreen.show();
		}
	}


}
