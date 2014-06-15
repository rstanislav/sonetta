import QtQuick 2.3
import "SessionStateController.js" as State

QtObject {
    id: root

    function back() {
        State.pop()
    }

    readonly property string initialStateName: State.initialState().name
    readonly property var initialStateParameters: State.initialState().parameters

    /* The parameters of the following signals correspond
      to the name and parameters of the NEW current state */
    signal statePushed(var name, var parameters)
    signal statePopped(var name, var parameters)
    signal stateReset(var name, var parameters)
    signal stateChanged(var name, var parameters)

    /* Specialized signals */
    signal playbackRequested()
    signal playlistsOverviewRequested()
    signal exploreRequested()
    signal settingsRequested()

    /* Specialized state transition functions */
    function playlistsOverview() {
        var state = State.create("playlists", {})
        State.push(state)
    }

    function playlist(index) {
        var state = State.create("playlist", { index: index })
        State.push(state)
    }

    function playback() {
        var state = State.create("playback", {})
        State.push(state)
    }

    function browseArtist(uri) {
        var state = State.create("browse", { type: "artist", uri: uri })
        State.push(state)
    }

    function browseAlbum(uri) {
        var state = State.create("browse", { type: "album", uri: uri })
        State.push(state)
    }

    function browsePlaylist(uri) {
        var state = State.create("browse", { type: "playlist", uri: uri })
        State.push(state)

    }

    function settings() {
        var state = State.create("settings", {})
        State.push(settings)
    }

    function explore() {
        var state = State.create("explore", {})
        State.push(state)
    }

    onStatePushed: stateChanged(name, parameters)
    onStatePopped: stateChanged(name, parameters)
    onStateReset: stateChanged(name, parameters)

    /* Handler */
    onStateChanged: {
        switch (name) {
        case "playback":
            playbackRequested()
            break
        case "playlists":
            playlistsOverviewRequested()
            break
        case "explore":
            exploreRequested()
            break
        case "settings":
            settingsRequested()
            break
        }
    }
}