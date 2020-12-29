/********************************************************************
 This file is part of the KDE project.

Copyright (C) 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/

import QtQuick 2.8
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.sessions 2.0
import "../components"

PlasmaCore.ColorScope {

    id: lockScreenUi
    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property bool lightBackground: Math.max(PlasmaCore.ColorScope.backgroundColor.r, PlasmaCore.ColorScope.backgroundColor.g, PlasmaCore.ColorScope.backgroundColor.b) > 0.5

    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

    Connections {
        target: authenticator
        function onFailed() {
            root.notification = i18nd("plasma_lookandfeel_org.kde.lookandfeel","Unlocking failed");
        }
        function onGraceLockedChanged() {
            if (!authenticator.graceLocked) {
                root.notification = "";
                root.clearPassword();
            }
        }
        function onMessage() {
            root.notification = msg;
        }
        function onError() {
            root.notification = err;
        }
    }

    SessionManagement {
        id: sessionManagement
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            root.clearPassword();
        }
    }

    SessionsModel {
        id: sessionsModel
        showNewSessionEntry: false
    }

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    Loader {
        id: changeSessionComponent
        active: false
        source: "ChangeSession.qml"
        visible: false
    }

    MouseArea {
        id: lockScreenRoot

        property bool uiVisible: false
        property bool blockUI: mainStack.depth > 1 || mainBlock.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive

        x: parent.x
        y: parent.y
        width: parent.width
        height: parent.height
        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }
        Keys.onEscapePressed: {
            uiVisible = !uiVisible;
            if (inputPanel.keyboardActive) {
                inputPanel.showHide();
            }
            if (!uiVisible) {
                root.clearPassword();
            }
        }
        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }
        Timer {
            id: fadeoutTimer
            interval: 10000
            onTriggered: {
                if (!lockScreenRoot.blockUI) {
                    lockScreenRoot.uiVisible = false;
                }
            }
        }

        Component.onCompleted: PropertyAnimation { id: launchAnimation; target: lockScreenRoot; property: "opacity"; from: 0; to: 1; duration: 1000 }

        states: [
            State {
                name: "onOtherSession"
                // for slide out animation
                PropertyChanges { target: lockScreenRoot; y: lockScreenRoot.height }
                // we also change the opacity just to be sure it's not visible even on unexpected screen dimension changes with possible race conditions
                PropertyChanges { target: lockScreenRoot; opacity: 0 }
            }
        ]

        transitions:
            Transition {
            // we only animate switchting to another session, because kscreenlocker doesn't get notified when
            // coming from another session back and so we wouldn't know when to trigger the animation exactly
            from: ""
            to: "onOtherSession"

            PropertyAnimation { id: stateChangeAnimation; properties: "y"; duration: 300; easing.type: Easing.InQuad}
            PropertyAnimation { properties: "opacity"; duration: 300}

            onRunningChanged: {
                // after the animation has finished switch session: since we only animate the transition TO state "onOtherSession"
                // and not the other way around, we don't have to check the state we transitioned into
                if (/* lockScreenRoot.state == "onOtherSession" && */ !running) {
                    mainStack.currentItem.switchSession()
                }
            }
        }

        WallpaperFader {
            anchors.fill: parent
            state: lockScreenRoot.uiVisible ? "on" : "off"
            source: wallpaper
            mainStack: mainStack
            footer: footer
            clock: clock
        }


        ListModel {
            id: users

            Component.onCompleted: {
                users.append({name: kscreenlocker_userName,
                                realName: kscreenlocker_userName,
                                icon: kscreenlocker_userImage,

                })
            }
        }

        StackView {
            id: mainStack
            anchors {
                left: parent.left
                right: parent.right
            }
            height: lockScreenRoot.height + units.gridUnit * 3
            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            initialItem: MainBlock {
                id: mainBlock
                lockScreenUiVisible: lockScreenRoot.uiVisible

                showUserList: userList.y + mainStack.y > 0

                Stack.onStatusChanged: {
                    // prepare for presenting again to the user
                    if (Stack.status == Stack.Activating) {
                        mainPasswordBox.remove(0, mainPasswordBox.length)
                        mainPasswordBox.focus = true
                    }
                }
                userListModel: users
                notificationMessage: {
                    var text = ""
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        text += i18nd("plasma_lookandfeel_org.kde.lookandfeel","Caps Lock is on")
                        if (root.notification) {
                            text += " • "
                        }
                    }
                    text += root.notification
                    return text
                }

                onLoginRequest: {
                    root.notification = ""
                    authenticator.tryUnlock(password)
                }

                actionItems: [
                    Image {
                        id: loginButton
                        source: "../assets/switch_primary.svgz"
                        smooth: true            
                        opacity: 1
                        sourceSize: Qt.size(80, 80)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // If there are no existing sessions to switch to, create a new one instead
                                if (((sessionsModel.showNewSessionEntry && sessionsModel.count === 1) ||
                                (!sessionsModel.showNewSessionEntry && sessionsModel.count === 0)) &&
                                sessionsModel.canSwitchUser) {
                                    mainStack.pop({immediate:true})
                                    sessionsModel.startNewSession(true /* lock the screen too */)
                                    lockScreenRoot.state = ''
                                } else {
                                    mainStack.push(switchSessionPage)
                                }
                            }
                        }
                        visible: sessionsModel.canStartNewSession && sessionsModel.canSwitchUser
                        anchors { verticalCenter: parent.top }                        
                    }
                ]

                Loader {
                    Layout.topMargin: PlasmaCore.Units.smallSpacing // some distance to the password field
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: config.showMediaControls
                    source: "MediaControls.qml"
                }
            }

            Component.onCompleted: {
                if (defaultToSwitchUser) { //context property
                    // If we are in the only session, then going to the session switcher is
                    // a pointless extra step; instead create a new session immediately
                    if (((sessionsModel.showNewSessionEntry && sessionsModel.count === 1)  ||
                       (!sessionsModel.showNewSessionEntry && sessionsModel.count === 0)) &&
                       sessionsModel.canStartNewSession) {
                        sessionsModel.startNewSession(true /* lock the screen too */)
                    } else {
                        mainStack.push({
                            item: switchSessionPage,
                            immediate: true});
                    }
                }
            }
        }

        Loader {
            id: inputPanel
            state: "hidden"
            readonly property bool keyboardActive: item ? item.active : false
            anchors {
                left: parent.left
                right: parent.right
            }
            function showHide() {
                state = state == "hidden" ? "visible" : "hidden";
            }
            Component.onCompleted: inputPanel.source = "../components/VirtualKeyboard.qml"

            onKeyboardActiveChanged: {
                if (keyboardActive) {
                    state = "visible";
                } else {
                    state = "hidden";
                }
            }

            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: mainStack
                        y: Math.min(0, lockScreenRoot.height - inputPanel.height - mainBlock.visibleBoundary)
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: lockScreenRoot.height - inputPanel.height
                        opacity: 1
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: mainStack
                        y: 0
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: lockScreenRoot.height - lockScreenRoot.height/4
                        opacity: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                inputPanel.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }

        Component {
            id: switchSessionPage
            SessionManagementScreen {
                property var switchSession: finalSwitchSession

                Stack.onStatusChanged: {
                    if (Stack.status == Stack.Activating) {
                        focus = true
                    }
                }

                userListModel: sessionsModel

                // initiating animation of lockscreen for session switch
                function initSwitchSession() {
                    lockScreenRoot.state = 'onOtherSession'
                }

                // initiating session switch and preparing lockscreen for possible return of user
                function finalSwitchSession() {
                    mainStack.pop({immediate:true})
                    sessionsModel.switchUser(userListCurrentModelData.vtNumber)
                    lockScreenRoot.state = ''
                }

                Keys.onLeftPressed: userList.decrementCurrentIndex()
                Keys.onRightPressed: userList.incrementCurrentIndex()
                Keys.onEnterPressed: initSwitchSession()
                Keys.onReturnPressed: initSwitchSession()
                Keys.onEscapePressed: mainStack.pop()

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true

                        PlasmaComponents3.Label {
                            id: switchToCurrent
                            Layout.fillWidth: true
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Switch to This Session")
                            font.pointSize: Math.max(fontSize + 2,theme.defaultFont.pointSize + 2)
                            textFormat: Text.PlainText
                            color: "white"
                            maximumLineCount: 1
                        }

                        Image {
                            id: loginButton
                            source: "../assets/login.svgz"
                            sourceSize: Qt.size(switchToCurrent.height, switchToCurrent.height)
                            smooth: true            
                            anchors {
                                verticalCenter: switchToCurrent.verticalCenter
                                left: switchToCurrent.right
                            }
                            anchors.leftMargin: 8   
                            opacity: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: initSwitchSession();
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        PlasmaComponents3.Label {
                            id: switchToOther
                            Layout.fillWidth: true
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Start New Session")
                            font.pointSize: Math.max(fontSize + 2,theme.defaultFont.pointSize + 2)
                            textFormat: Text.PlainText
                            color: "white"
                            maximumLineCount: 1
                        }

                        Image {
                            id: switchToCurrentButton
                            source: "../assets/switch_primary.svgz"
                            sourceSize: Qt.size(switchToOther.height, switchToOther.height)
                            smooth: true            
                            anchors {
                                verticalCenter: switchToOther.verticalCenter
                                left: switchToOther.right
                            }
                            anchors.leftMargin: 8   
                            opacity: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    mainStack.pop({immediate:true})
                                    sessionsModel.startNewSession(true /* lock the screen too */)
                                    lockScreenRoot.state = ''
                                }
                            }
                        }
                    }

                }

                actionItems: [
                    
                    Image {
                        id: backButton
                        source: "../assets/back.svgz"
                        smooth: true            
                        opacity: 1
                        sourceSize: Qt.size(80, 80)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainStack.pop()
                        }
                        anchors { verticalCenter: parent.top }                        
                    }
                ]
            }
        }

        Loader {
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: units.largeSpacing
            }
        }

        RowLayout {
            id: footer
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: units.smallSpacing
            }

            PlasmaComponents3.ToolButton {
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                onClicked: inputPanel.showHide()

                visible: inputPanel.status == Loader.Ready
            }

            KeyboardLayoutButton {
            }

            Item {
                Layout.fillWidth: true
            }

            Battery {}
        }
    }

    Component.onCompleted: {
        // version support checks
        if (root.interfaceVersion < 1) {
            // ksmserver of 5.4, with greeter of 5.5
            root.viewVisible = true;
        }
    }
}
