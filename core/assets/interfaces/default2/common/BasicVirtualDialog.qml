import QtQuick 2.2
import QtGraphicalEffects 1.0
import Navigation 0.1

import "."

FocusScope {
    id: root

    property Component dialog: null

    signal activated
    signal deactivated

    z: 10
    states: [
        State {
            name: "activating"
            PropertyChanges { target: loader; active: true }
            PropertyChanges { target: root; focus: true; visible: true }
        },
        State {
            name: "active"
            PropertyChanges { target: loader; active: true }
            PropertyChanges { target: root; focus: true; visible: true }
            StateChangeScript { script: root.activated() }
            PropertyChanges { target: m.findMainContent(root.parent); visible: false }
        },
        State {
            name: "deactivating"
            PropertyChanges { target: loader; active: true }
            PropertyChanges { target: m.findMainContent(root.parent); visible: true }
        },
        State {
            name: "inactive"
            PropertyChanges { target: root; focus: false; visible: false }
            PropertyChanges { target: loader; active: false }
        }
    ]
    state: "inactive"

    transitions: Transition {
        from: "deactivating"
        to: "inactive"
        // Make this part of transition so that it's not run on initial state
        ScriptAction { script: root.deactivated() }
    }

    Loader {
        id: loader
        anchors.fill: parent
        focus: true
        sourceComponent: Item {
            // Need to replicate states here because this item is not
            // accessible from root's scope
            states: [
                State {
                    name: "activating"
                    when: root.state === "activating"
                    PropertyChanges { target: blur; radius: UI.dialog.blurRadius }
                    PropertyChanges { target: brightness; brightness: UI.dialog.brightnessDelta }
                    PropertyChanges { target: dialogLoader; scale: 1 }
                },
                State {
                    name: "active"
                    when: root.state === "active"
                    PropertyChanges { target: blur; radius: UI.dialog.blurRadius }
                    PropertyChanges { target: brightness; brightness: UI.dialog.brightnessDelta }
                    PropertyChanges { target: dialogLoader; scale: 1 }
                },
                State {
                    name : "deactivating"
                    when: root.state === "deactivating"
                    PropertyChanges { target: blur; radius: 0 }
                    PropertyChanges { target: brightness; brightness: 0 }
                    PropertyChanges { target: dialogLoader; scale: 0 }
                },
                State {
                    name: "inactive"
                    when: root.state === "inactive"
                    PropertyChanges { target: blur; radius: 0 }
                    PropertyChanges { target: brightness; brightness: 0 }
                    PropertyChanges { target: dialogLoader; scale: 0 }
                }
            ]
            state: "inactive"

            transitions: [
                Transition {
                    from: "inactive"
                    to: "activating"
                    SmoothedAnimation { targets: [blur, brightness]; properties: "radius,brightness"; duration: UI.timing.dialogPopup; velocity: -1 }
                    SequentialAnimation {
                        SmoothedAnimation { target: dialogLoader; property: "scale"; duration: UI.timing.dialogPopup; velocity: -1 }
                        ScriptAction { script: m.advanceState() }
                    }
                },
                Transition {
                    from: "active"
                    to: "deactivating"
                    SmoothedAnimation { targets: [blur, brightness]; properties: "radius,brightness"; duration: UI.timing.dialogPopup; velocity: -1 }
                    SequentialAnimation {
                        SmoothedAnimation { target: dialogLoader; property: "scale"; duration: UI.timing.dialogPopup; velocity: -1 }
                        ScriptAction { script: m.advanceState() }
                    }
                }
            ]

            FastBlur {
                id: blur
                anchors.fill: parent
                source: brightness
            }

            BrightnessContrast {
                id: brightness
                source: m.findMainContent(root.parent)
                anchors.fill: parent
                visible: false
            }

            Loader {
                id: dialogLoader
                focus: true
                anchors.fill: parent
                sourceComponent: root.dialog
                scale: 0
            }
        }
    }

    QtObject {
        id: m

        function findRoot(parent) {
            while (parent.parent)
                parent = parent.parent

            return parent
        }

        function findMainContent(root) {
            for (var i = 0; i < root.children.length; ++i)
            {
                var child = root.children[i]
                if (child._tagContent)
                    return child
            }

            return null
        }

        function advanceState() {
            // Advance state when animations are finished
            if (root.state == "activating")
                root.state = "active"
            else if (root.state == "deactivating")
                root.state = "inactive"
        }
    }

    function activate() {
        if (root.state == "inactive")
            root.state = "activating"
    }

    function deactivate() {
        if (root.state == "active")
            root.state = "deactivating"
    }

    Component.onCompleted: {
        // Parent item to root
        root.parent = m.findRoot(root.parent)
        anchors.fill = root.parent
    }

    Keys.forwardTo: Nav {
        onBack: deactivate()
        onButtonPressed: { event.accepted = true }
    }

    Keys.onPressed: {
        // NOTE: Fix this in C++. With Qt 5.3 it should finally be possible to
        // intercept key events from an attached item, giving rise to a Nav.onButtonPressed() syntax,
        // identical to that of "Keys".
        if (event.key === Qt.Key_Escape)
            deactivate()
        else
            event.accepted = true
    }
}
