import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtCore
import qs.Bar
import qs.Bar.Modules
import qs.Widgets
import qs.Widgets.LockScreen
import qs.Widgets.Notification
import qs.Widgets.SettingsWindow
import qs.Settings
import qs.Helpers

Scope {
    id: root

    property var notificationHistoryWin: notificationHistoryLoader.active ? notificationHistoryLoader.item : null
    property var settingsWindow: null
    property bool pendingReload: false
    
    // Function to load notification history
    function loadNotificationHistory() {
        if (!notificationHistoryLoader.active) {
            notificationHistoryLoader.loading = true;
        }
        return notificationHistoryLoader;
    }

    // Helper function to round value to nearest step
    function roundToStep(value, step) {
        return Math.round(value / step) * step;
    }

    // Volume property reflecting current audio volume in 0-100
    // Will be kept in sync dynamically below
    property int volume: (defaultAudioSink && defaultAudioSink.audio && !defaultAudioSink.audio.muted)
                        ? Math.round(defaultAudioSink.audio.volume * 100)
                        : 0

    // Function to update volume with clamping, stepping, and applying to audio sink
    function updateVolume(vol) {
        var clamped = Math.max(0, Math.min(100, vol));
        var stepped = roundToStep(clamped, 5);
        if (defaultAudioSink && defaultAudioSink.audio) {
            defaultAudioSink.audio.volume = stepped / 100;
        }
        volume = stepped;
    }

    // Microphone volume property reflecting current input volume in 0-100
    // Will be kept in sync dynamically below
    property int micVolume: (defaultAudioSource && defaultAudioSource.audio && !defaultAudioSource.audio.muted)
                           ? Math.round(defaultAudioSource.audio.volume * 100)
                           : 0

    // Property to track if microphone is actively being used by a program
    property bool micInUse: false

    // Function to update microphone volume with clamping, stepping, and applying to audio source
    function updateMicVolume(vol) {
        var clamped = Math.max(0, Math.min(100, vol));
        var stepped = roundToStep(clamped, 5);
        if (defaultAudioSource && defaultAudioSource.audio) {
            defaultAudioSource.audio.volume = stepped / 100;
        }
        micVolume = stepped;
    }

    // Function to toggle microphone mute
    function toggleMicMute() {
        if (defaultAudioSource && defaultAudioSource.audio) {
            defaultAudioSource.audio.muted = !defaultAudioSource.audio.muted;
        }
    }

    // Function to check if microphone is being used by any program
    function updateMicInUse() {
        if (!defaultAudioSource || !Pipewire.nodes || !Pipewire.nodes.values) {
            micInUse = false;
            return;
        }

        // Check if there are any active stream nodes connected to the microphone source
        var inUse = false;
        for (var i = 0; i < Pipewire.nodes.values.length; ++i) {
            var node = Pipewire.nodes.values[i];
            // A stream node that is a source (recording from microphone) indicates mic is in use
            if (node.isStream && !node.isSink && node.audio) {
                inUse = true;
                break;
            }
        }
        micInUse = inUse;
    }

    Component.onCompleted: {
        Quickshell.shell = root;
        root.updateMicInUse();
    }

    Background {}
    Overview {}

    Bar {
        id: bar
        shell: root
        property var notificationHistoryWin: notificationHistoryLoader.active ? notificationHistoryLoader.item : null
    }

    Dock {
        id: dock
    }

    Applauncher {
        id: appLauncherPanel
        visible: false
    }

    LockScreen {
        id: lockScreen
        onLockedChanged: {
            if (!locked && root.pendingReload) {
                reloadTimer.restart();
                root.pendingReload = false;
            }
        }
    }

    IdleInhibitor {
        id: idleInhibitor
    }

    NotificationServer {
        id: notificationServer
        onNotification: function (notification) {
            console.log("[Notification] Received notification:", notification.appName, "-", notification.summary);
            notification.tracked = true;
            if (notificationPopup.notificationsVisible) {
                // Add notification to the popup manager
                notificationPopup.addNotification(notification);
            }
            if (notificationHistoryLoader.active && notificationHistoryLoader.item) {
                notificationHistoryLoader.item.addToHistory({
                    id: notification.id,
                    appName: notification.appName || "Notification",
                    summary: notification.summary || "",
                    body: notification.body || "",
                    urgency: notification.urgency,
                    timestamp: Date.now()
                });
            }
        }
    }

    NotificationPopup {
        id: notificationPopup
    }

    // LazyLoader for NotificationHistory - only load when needed
    LazyLoader {
        id: notificationHistoryLoader
        loading: false
        component: NotificationHistory {}
    }

    // Centralized LazyLoader for SettingsWindow - prevents crashes on multiple opens
    LazyLoader {
        id: settingsWindowLoader
        loading: false
        component: SettingsWindow {
            Component.onCompleted: {
                root.settingsWindow = this;
            }
        }
    }

    // Function to safely show/hide settings window
    function toggleSettingsWindow() {
        if (!settingsWindowLoader.active) {
            settingsWindowLoader.loading = true;
        }
        
        if (settingsWindowLoader.item) {
            settingsWindowLoader.item.visible = !settingsWindowLoader.item.visible;
        }
    }

    // Reference to the default audio sink from Pipewire
    property var defaultAudioSink: Pipewire.defaultAudioSink

    // Reference to the default audio source (microphone) from Pipewire
    property var defaultAudioSource: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // Track all Pipewire nodes to detect microphone usage
    PwObjectTracker {
        id: allNodesTracker
        objects: Pipewire.nodes
    }

    // Update microphone usage state when nodes change
    Connections {
        target: Pipewire.nodes
        function onValuesChanged() {
            root.updateMicInUse();
        }
    }

    IPCHandlers {
        appLauncherPanel: appLauncherPanel
        lockScreen: lockScreen
        idleInhibitor: idleInhibitor
        notificationPopup: notificationPopup
    }

    Connections {
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup();
        }

        target: Quickshell
    }

    Connections {
        target: defaultAudioSink ? defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (defaultAudioSink.audio && !defaultAudioSink.audio.muted) {
                volume = Math.round(defaultAudioSink.audio.volume * 100);
                console.log("Volume changed externally to:", volume);
            }
        }
        function onMutedChanged() {
            if (defaultAudioSink.audio) {
                if (defaultAudioSink.audio.muted) {
                    volume = 0;
                    console.log("Audio muted, volume set to 0");
                } else {
                    volume = Math.round(defaultAudioSink.audio.volume * 100);
                    console.log("Audio unmuted, volume restored to:", volume);
                }
            }
        }
    }

    Connections {
        target: defaultAudioSource ? defaultAudioSource.audio : null
        function onVolumeChanged() {
            if (defaultAudioSource.audio && !defaultAudioSource.audio.muted) {
                micVolume = Math.round(defaultAudioSource.audio.volume * 100);
                console.log("Microphone volume changed externally to:", micVolume);
            }
        }
        function onMutedChanged() {
            if (defaultAudioSource.audio) {
                if (defaultAudioSource.audio.muted) {
                    console.log("Microphone muted");
                } else {
                    micVolume = Math.round(defaultAudioSource.audio.volume * 100);
                    console.log("Microphone unmuted, volume:", micVolume);
                }
            }
        }
    }

}