import QtQuick
import Quickshell
import qs.Settings
import qs.Components
import qs.Bar.Modules

Item {
    id: micDisplay
    property var shell
    property int micVolume: 0
    property bool firstChange: true

    width: pillIndicator.width
    height: pillIndicator.height

    function getMicColor() {
        // If microphone is actively being used by a program, show red background
        if (shell && shell.micInUse && !isMuted()) {
            return "#ef4444"; // Red color to indicate mic is in use
        }
        if (micVolume <= 100) return Theme.accentPrimary;
        // Calculate interpolation factor (0 at 100%, 1 at 200%)
        var factor = (micVolume - 100) / 100;
        // Blend between accent and warning colors
        return Qt.rgba(
            Theme.accentPrimary.r + (Theme.warning.r - Theme.accentPrimary.r) * factor,
            Theme.accentPrimary.g + (Theme.warning.g - Theme.accentPrimary.g) * factor,
            Theme.accentPrimary.b + (Theme.warning.b - Theme.accentPrimary.b) * factor,
            1
        );
    }

    function getIconColor() {
        if (micVolume <= 100) return Theme.textPrimary;
        return getMicColor(); // Only use warning blend when >100%
    }

    function isMuted() {
        return shell && shell.defaultAudioSource && shell.defaultAudioSource.audio && shell.defaultAudioSource.audio.muted;
    }

    PillIndicator {
        id: pillIndicator
        icon: isMuted() ? "mic_off" : "mic"
        text: micVolume + "%"

        pillColor: Theme.surfaceVariant
        iconCircleColor: isMuted() ? Theme.textSecondary : getMicColor()
        iconTextColor: Theme.backgroundPrimary
        textColor: Theme.textPrimary
        collapsedIconColor: getIconColor()
        autoHide: true

        StyledTooltip {
            id: micTooltip
            text: "Microphone: " + micVolume + "%" +
                  (shell && shell.micInUse ? " (IN USE)" : "") +
                  "\nLeft click to mute/unmute.\nRight click for input devices.\nScroll up/down to change sensitivity." +
                  "\n\nRed background = mic is being used by a program"
            positionAbove: false
            tooltipVisible: !deviceSelector.visible && micDisplay.containsMouse
            targetItem: pillIndicator
            delay: 1500
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    // Left click: toggle mute
                    if (shell) {
                        shell.toggleMicMute();
                    }
                } else if (mouse.button === Qt.RightButton) {
                    // Right click: open device selector
                    if (deviceSelector.visible) {
                        deviceSelector.dismiss();
                    } else {
                        deviceSelector.show();
                    }
                }
            }
        }
    }

    Connections {
        target: shell ?? null
        function onMicVolumeChanged() {
            if (shell) {
                const clampedVolume = Math.max(0, Math.min(100, shell.micVolume));
                if (clampedVolume !== micVolume) {
                    micVolume = clampedVolume;
                    pillIndicator.text = micVolume + "%";
                    pillIndicator.icon = isMuted() ? "mic_off" : "mic";

                    if (firstChange) {
                        firstChange = false
                    }
                    else {
                        pillIndicator.show();
                    }
                }
            }
        }
        function onMicInUseChanged() {
            // Update icon color when microphone usage state changes
            pillIndicator.iconCircleColor = Qt.binding(function() {
                return isMuted() ? Theme.textSecondary : getMicColor();
            });
        }
    }

    // Track mute state changes
    Connections {
        target: shell && shell.defaultAudioSource ? shell.defaultAudioSource.audio : null
        function onMutedChanged() {
            pillIndicator.icon = isMuted() ? "mic_off" : "mic";
            pillIndicator.iconCircleColor = Qt.binding(function() {
                return isMuted() ? Theme.textSecondary : getMicColor();
            });
            pillIndicator.show();
        }
    }

    Component.onCompleted: {
        if (shell && shell.micVolume !== undefined) {
            micVolume = Math.max(0, Math.min(100, shell.micVolume));
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: {
            micDisplay.containsMouse = true
            pillIndicator.autoHide = false;
            pillIndicator.showDelayed()
        }
        onExited: {
            micDisplay.containsMouse = false
            pillIndicator.autoHide = true;
            pillIndicator.hide()
        }
        cursorShape: Qt.PointingHandCursor
        onWheel: (wheel) => {
            if (!shell) return;
            let step = 5;
            if (wheel.angleDelta.y > 0) {
                shell.updateMicVolume(Math.min(100, shell.micVolume + step));
            } else if (wheel.angleDelta.y < 0) {
                shell.updateMicVolume(Math.max(0, shell.micVolume - step));
            }
        }
    }

    MicDeviceSelector {
        id: deviceSelector
        onPanelClosed: deviceSelector.dismiss()
    }

    property bool containsMouse: false
}
