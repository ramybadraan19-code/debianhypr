// ==============================================================================
// DebRice SDDM theme — original glassmorphism design (not a macOS/Windows clone).
// A blurred animated background, frosted-glass login card, live clock, weather
// placeholder, and avatar, with smooth fade/slide transitions.
// ==============================================================================
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor || "#1e1e2e"

    property color accent: config.accentColor || "#cba6f7"

    // ---- Animated background: slow-drifting gradient blobs ----------------
    Image {
        id: bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    FastBlur {
        anchors.fill: bg
        source: bg
        radius: config.blurRadius || 40
    }
    Rectangle {
        anchors.fill: parent
        color: "#00000055"
    }

    Repeater {
        model: 3
        Rectangle {
            width: 380; height: 380; radius: 380
            color: root.accent
            opacity: 0.10
            x: Math.random() * root.width
            y: Math.random() * root.height
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: Math.random() * root.width; duration: 18000 + index*4000; easing.type: Easing.InOutSine }
                NumberAnimation { to: Math.random() * root.width; duration: 18000 + index*4000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: Math.random() * root.height; duration: 15000 + index*3000; easing.type: Easing.InOutSine }
                NumberAnimation { to: Math.random() * root.height; duration: 15000 + index*3000; easing.type: Easing.InOutSine }
            }
        }
    }

    // ---- Clock + date (top center) ----------------------------------------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 70
        spacing: 6
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), config.clockFormat || "HH:mm")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 84
            font.weight: Font.Bold
            color: config.foregroundColor || "#ffffff"
            Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatTime(new Date(), config.clockFormat || "HH:mm") }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), config.dateFormat || "dddd, d MMMM")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: config.foregroundColor || "#cdd6f4"
            opacity: 0.85
        }
    }

    // ---- Frosted glass login card ------------------------------------------
    Rectangle {
        id: card
        width: 380
        height: 420
        radius: 26
        anchors.centerIn: parent
        color: Qt.rgba(1, 1, 1, 0.08)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1
        opacity: 0
        Component.onCompleted: fadeIn.start()
        NumberAnimation { id: fadeIn; target: card; property: "opacity"; to: 1; duration: 700; easing.type: Easing.OutCubic }

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 24
            samples: 32
            color: "#00000088"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 18

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 92; height: 92; radius: 46
                color: Qt.rgba(1,1,1,0.12)
                border.color: root.accent
                border.width: 2
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 44
                    color: root.accent
                }
            }

            ComboBox {
                id: userCombo
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                onAccepted: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
                Component.onCompleted: forceActiveFocus()
            }

            ComboBox {
                id: sessionCombo
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
            }

            Button {
                Layout.fillWidth: true
                text: "Sign in"
                onClicked: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
                background: Rectangle { radius: 12; color: root.accent }
                contentItem: Text { text: parent.text; color: "#1e1e2e"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
            }
        }
    }

    // ---- Power row (bottom) -----------------------------------------------
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20
        Text { text: "⏻"; color: "#ffffff"; font.pixelSize: 22
            MouseArea { anchors.fill: parent; onClicked: sddm.powerOff() } }
        Text { text: "⟲"; color: "#ffffff"; font.pixelSize: 22
            MouseArea { anchors.fill: parent; onClicked: sddm.reboot() } }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            passwordField.placeholderText = "Wrong password, try again"
        }
    }
}
