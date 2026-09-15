import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: root
	screenTitle: qsTr("Spotify verbinden")

	// 0 = credentials, 1 = auth URL, 2 = enter code, 3 = connected
	property int step : 0
	property string authUrl : ""

	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}

	onShown: {
		screenStateController.screenColorDimmedIsReachable = false;
		app.spotifyStatus = (app.spotifyStatus == "error") ? "" : app.spotifyStatus;  // clear stale error on entry
		if (app.spotifyStatus == "configured") {
			step = 3;
		} else if (app.spotifyClientId.length > 0) {
			clientIdLabel.inputText = app.spotifyClientId;
			clientSecretLabel.inputText = "";
			step = 0;
		} else {
			step = 0;
		}
	}

	// ── Step 0: Enter credentials ─────────────────────────────────────────

	Column {
		id: credentialsView
		visible: step == 0
		anchors {
			top: parent.top
			topMargin: 20
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 10

		Text {
			width: parent.width
			font.pixelSize: isNxt ? 20 : 16
			font.family: qfont.regular.name
			wrapMode: Text.WordWrap
			text: "Maak een Spotify app aan op developer.spotify.com en voer je Client ID en Client Secret in. Stel als redirect URI in: https://example.com"
		}

		Item {
			width: parent.width
			height: childrenRect.height

			EditTextLabel4421 {
				id: clientIdLabel
				width: isNxt ? 800 : 600
				height: editClientIdButton.height
				leftText: qsTr("Client ID")
				leftTextAvailableWidth: isNxt ? 200 : 160
				onClicked: openClientIdKeyboard()
			}

			IconButton {
				id: editClientIdButton
				width: 40
				anchors {
					bottom: clientIdLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"
				onClicked: openClientIdKeyboard()
			}
		}

		Item {
			width: parent.width
			height: childrenRect.height

			EditTextLabel4421 {
				id: clientSecretLabel
				width: isNxt ? 800 : 600
				height: editClientSecretButton.height
				leftText: qsTr("Client Secret")
				leftTextAvailableWidth: isNxt ? 200 : 160
				onClicked: openClientSecretKeyboard()
			}

			IconButton {
				id: editClientSecretButton
				width: 40
				anchors {
					bottom: clientSecretLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"
				onClicked: openClientSecretKeyboard()
			}
		}

		StandardButton {
			width: isNxt ? 350 : 280
			radius: 5
			text: qsTr("Haal login URL op")
			fontPixelSize: isNxt ? 25 : 20
			onClicked: {
				app.spotifyClientId = clientIdLabel.inputText;
				if (clientSecretLabel.inputText.length > 0)
					app.spotifyClientSecret = clientSecretLabel.inputText;
				app.saveSettings();
				app.saveTokenFile();   // persist immediately: survives abandoning the flow midway
				authUrl = app.buildSpotifyAuthUrl();
				step = 1;
			}
		}
	}

	// ── Step 1: Show auth URL ─────────────────────────────────────────────

	Column {
		id: authUrlView
		visible: step == 1
		anchors {
			top: parent.top
			topMargin: 20
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 12

		Text {
			width: parent.width
			font.pixelSize: isNxt ? 20 : 16
			font.family: qfont.regular.name
			wrapMode: Text.WordWrap
			text: "Bezoek de onderstaande URL op je telefoon of computer en log in met Spotify:"
		}

		Rectangle {
			width: parent.width
			height: authUrlText.height + 16
			color: "#f0f0f0"
			radius: 4

			TextEdit {
				id: authUrlText
				anchors {
					top: parent.top
					topMargin: 8
					left: parent.left
					leftMargin: 8
					right: parent.right
					rightMargin: 8
				}
				font.pixelSize: isNxt ? 14 : 11
				font.family: qfont.regular.name
				wrapMode: Text.WrapAnywhere
				readOnly: true
				text: authUrl
			}
		}

		Text {
			width: parent.width
			font.pixelSize: isNxt ? 18 : 14
			font.family: qfont.regular.name
			wrapMode: Text.WordWrap
			text: "Na het inloggen word je doorgestuurd naar example.com. Kopieer de waarde na \"code=\" uit de adresbalk van je browser."
		}

		Row {
			spacing: 16

			StandardButton {
				width: isNxt ? 220 : 176
				radius: 5
				text: qsTr("Terug")
				fontPixelSize: isNxt ? 25 : 20
				onClicked: step = 0
			}

			StandardButton {
				width: isNxt ? 280 : 224
				radius: 5
				text: qsTr("Ik heb de code →")
				fontPixelSize: isNxt ? 25 : 20
				onClicked: step = 2
			}
		}
	}

	// ── Step 2: Enter authorization code ─────────────────────────────────

	Column {
		id: codeView
		visible: step == 2
		anchors {
			top: parent.top
			topMargin: 20
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 10

		Text {
			width: parent.width
			font.pixelSize: isNxt ? 20 : 16
			font.family: qfont.regular.name
			wrapMode: Text.WordWrap
			text: "Plak hier de code uit de adresbalk (het lange stuk tekst na \"code=\"):"
		}

		Item {
			width: parent.width
			height: childrenRect.height

			EditTextLabel4421 {
				id: authCodeLabel
				width: isNxt ? 800 : 600
				height: editAuthCodeButton.height
				leftText: qsTr("Code")
				leftTextAvailableWidth: isNxt ? 100 : 80
				onClicked: openAuthCodeKeyboard()
			}

			IconButton {
				id: editAuthCodeButton
				width: 40
				anchors {
					bottom: authCodeLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"
				onClicked: openAuthCodeKeyboard()
			}
		}

		Text {
			id: connectStatusText
			width: parent.width
			font.pixelSize: isNxt ? 16 : 13
			font.family: qfont.regular.name
			color: "red"
			wrapMode: Text.WordWrap
			visible: app.spotifyStatus == "error"
			text: "Verbinden mislukt. Controleer de code en probeer opnieuw."
		}

		Row {
			spacing: 16

			StandardButton {
				width: isNxt ? 220 : 176
				radius: 5
				text: qsTr("Terug")
				fontPixelSize: isNxt ? 25 : 20
				onClicked: step = 1
			}

			StandardButton {
				width: isNxt ? 320 : 256
				radius: 5
				text: qsTr("Verbind met Spotify")
				fontPixelSize: isNxt ? 25 : 20
				onClicked: {
					app.spotifyStatus = "";   // clear any error state
					app.exchangeCodeForToken(authCodeLabel.inputText);
				}
			}
		}
	}

	// ── Step 3: Connected ─────────────────────────────────────────────────

	Column {
		id: connectedView
		visible: step == 3
		anchors {
			top: parent.top
			topMargin: 40
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 16

		Text {
			font.pixelSize: isNxt ? 25 : 20
			font.family: qfont.semiBold.name
			text: qsTr("Verbonden met Spotify")
		}

		Text {
			font.pixelSize: isNxt ? 20 : 16
			font.family: qfont.regular.name
			text: app.spotifyDisplayName.length > 0 ? qsTr("Ingelogd als: ") + app.spotifyDisplayName : ""
		}

		StandardButton {
			width: isNxt ? 280 : 224
			radius: 5
			text: qsTr("Verbreek verbinding")
			fontPixelSize: isNxt ? 25 : 20
			onClicked: {
				app.disconnectSpotify();
				step = 0;
			}
		}
	}

	// ── Watch for successful login to advance to step 3 ──────────────────

	Connections {
		target: app
		onSpotifyStatusChanged: {
			if (app.spotifyStatus == "configured") {
				step = 3;
			}
		}
	}

	// ── Keyboard helpers ─────────────────────────────────────────────────

	function openClientIdKeyboard() {
		qkeyboard.open(qsTr("Voer Client ID in"), clientIdLabel.inputText, function(text) {
			if (text) clientIdLabel.inputText = text;
		});
	}

	function openClientSecretKeyboard() {
		qkeyboard.open(qsTr("Voer Client Secret in"), "", function(text) {
			if (text) clientSecretLabel.inputText = text;
		});
	}

	function openAuthCodeKeyboard() {
		qkeyboard.open(qsTr("Voer de code in"), authCodeLabel.inputText, function(text) {
			if (text) authCodeLabel.inputText = text;
		});
	}
}
