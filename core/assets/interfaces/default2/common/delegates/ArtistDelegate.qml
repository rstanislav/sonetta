import QtQuick 2.3

import "../../common"

ComponentAndTextDelegate {
    id: root
    focus: true
    text: model && model.name ? model.name : ""

    property url portrait: model && model.normalPortraitUri ? model.normalPortraitUri : ""

    component: SpotifyImage {
        anchors.fill: parent
        uri: root.portrait
        fillMode: Image.PreserveAspectCrop
        placeholder: "../../images/disc_placeholder_small.png"
    }
}
