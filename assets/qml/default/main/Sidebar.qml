import QtQuick 2.2
import Sonetta 0.1
import "../common"

FocusScope {
    id: root

    property alias currentIndex: list.currentIndex

    Image {
        source: "../images/dark.png"
        anchors.fill: parent
        fillMode: Image.Tile
    }

    Image {
        id: sonettaLogo
        source: "../images/sonetta.png"
        anchors {
            top: root.top
            horizontalCenter: root.horizontalCenter
            topMargin: 20
        }
    }

    MainMenuList {
        id: list
        focus: true
        anchors {
            left: root.left
            right: root.right
            top: sonettaLogo.bottom
            bottom: root.bottom
            topMargin: ui.misc.globalPadding
        }
    }
}
