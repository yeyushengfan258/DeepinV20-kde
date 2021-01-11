/***************************************************************************
 *   Copyright (C) 2014 by Aleix Pol Gonzalez <aleixpol@blue-systems.com>  *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.12 as QQC2
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kcoreaddons 1.0 as KCoreAddons

import org.kde.plasma.private.sessions 2.0
import "../components"
import "timer.js" as AutoTriggerTimer


PlasmaCore.ColorScope {
    id: root

    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
    height: screenGeometry.height
    width: screenGeometry.width

    signal logoutRequested()
    signal haltRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal cancelRequested()
    signal lockScreenRequested()

    property alias backgroundColor: backgroundRect.color

    function sleepRequested() {
        root.suspendRequested(2);
    }

    function hibernateRequested() {
        root.suspendRequested(4);
    }
 
    property real timeout: 30
    property real remainingTime: root.timeout
    property real factor: 50
    property var currentAction: {
        switch (sdtype) {
            case ShutdownType.ShutdownTypeReboot:
                return root.rebootRequested;
            case ShutdownType.ShutdownTypeHalt:
                return root.haltRequested;
            default:
                return root.logoutRequested;
        }
    }

    KCoreAddons.KUser {
        id: kuser
    }

    // For showing a "other users are logged in" hint
    SessionsModel {
        id: sessionsModel
        includeUnusedSessions: false
    }

    QQC2.Action {
        onTriggered: root.cancelRequested()
        shortcut: "Escape"
    }

    onRemainingTimeChanged: {
        if (remainingTime <= 0) {
            root.currentAction();
        }
    }

    Timer {
        id: countDownTimer
        running: true
        repeat: true
        interval: 1000
        onTriggered: remainingTime--
        Component.onCompleted: {
            AutoTriggerTimer.addCancelAutoTriggerCallback(function() {
                countDownTimer.running = false;
            });
        }
    }

    Behavior on factor {
        NumberAnimation {
            target: wallpaperBlur
            property: "factor"
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }    

    function isLightColor(color) {
        return Math.max(color.r, color.g, color.b) > 0.5
    }

    Image {
        id: wallpaper
        source: '../images/background.jpg'
        anchors.fill: parent
        smooth: true
        visible: false        
    }

    FastBlur {
        id: wallpaperBlur
        source: wallpaper
        anchors.fill: wallpaper
        radius: root.factor
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent

        color: "black"
        opacity: 0.55
    }


    MouseArea {
        anchors.fill: parent
        onClicked: root.cancelRequested()
    }
    UserDelegate {
        width: units.gridUnit * 7
        height: width
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.verticalCenter
        }
        constrainText: false
        avatarPath: kuser.faceIconUrl
        iconSource: "user-identity"
        isCurrent: true
        name: kuser.fullName
    }
    ColumnLayout {
        anchors {
            top: parent.verticalCenter
            topMargin: units.gridUnit * 2
            horizontalCenter: parent.horizontalCenter
        }
        spacing: units.largeSpacing

        height: Math.max(implicitHeight, units.gridUnit * 10)
        width: Math.max(implicitWidth, units.gridUnit * 16)

        PlasmaComponents.Label {
            font.pointSize: theme.defaultFont.pointSize + 1
            Layout.maximumWidth: units.gridUnit * 16
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18ndp("plasma_lookandfeel_org.kde.lookandfeel",
                         "One other user is currently logged in. If the computer is shut down or restarted, that user may lose work.",
                         "%1 other users are currently logged in. If the computer is shut down or restarted, those users may lose work.",
                         sessionsModel.count)
            visible: sessionsModel.count > 1
        }

        PlasmaComponents.Label {
            font.pointSize: theme.defaultFont.pointSize + 1
            Layout.maximumWidth: units.gridUnit * 16
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter the firmware setup screen.")
            visible: rebootToFirmwareSetup
        }

        RowLayout {
            spacing: units.largeSpacing * 2
            Layout.alignment: Qt.AlignHCenter
            LogoutButton {
                id: suspendButton
                iconSource: "../assets/suspend_primary.svgz"
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Sleep")
                textColor: "white"                
                action: root.sleepRequested
                KeyNavigation.left: logoutButton
                KeyNavigation.right: hibernateButton
                visible: spdMethods.SuspendState
            }
            LogoutButton {
                id: hibernateButton
                iconSource: "../assets/login.svgz"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Hibernate")
                textColor: "white"                                
                action: root.hibernateRequested
                KeyNavigation.left: suspendButton
                KeyNavigation.right: rebootButton
                visible: spdMethods.HibernateState
            }
            LogoutButton {
                id: rebootButton
                iconSource: "../assets/restart_primary.svgz"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Restart")
                textColor: "white"                                
                action: root.rebootRequested
                KeyNavigation.left: hibernateButton
                KeyNavigation.right: shutdownButton
                focus: sdtype === ShutdownType.ShutdownTypeReboot
                visible: maysd
            }
            LogoutButton {
                id: shutdownButton
                iconSource: "../assets/shutdown_primary.svgz"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Shut Down")
                textColor: "white"                                
                action: root.haltRequested
                KeyNavigation.left: rebootButton
                KeyNavigation.right: logoutButton
                focus: sdtype === ShutdownType.ShutdownTypeHalt
                visible: maysd
            }
            LogoutButton {
                id: logoutButton
                iconSource: "../assets/login.svgz"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Log Out")
                textColor: "white"                                
                action: root.logoutRequested
                KeyNavigation.left: shutdownButton
                KeyNavigation.right: suspendButton
                focus: sdtype === ShutdownType.ShutdownTypeNone
                visible: canLogout
            }
        }

        PlasmaComponents.Label {
            font.pointSize: theme.defaultFont.pointSize + 1
            Layout.alignment: Qt.AlignHCenter
            //opacity, as visible would re-layout
            opacity: countDownTimer.running ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            color: "white"
            text: {
                switch (sdtype) {
                    case ShutdownType.ShutdownTypeReboot:
                        return i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Restarting in 1 second", "Restarting in %1 seconds", root.remainingTime);
                    case ShutdownType.ShutdownTypeHalt:
                        return i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Shutting down in 1 second", "Shutting down in %1 seconds", root.remainingTime);
                    default:
                        return i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Logging out in 1 second", "Logging out in %1 seconds", root.remainingTime);
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            SecondaryButton {
                implicitWidth: units.gridUnit * 6
                font.pointSize: theme.defaultFont.pointSize + 1
                enabled: root.currentAction !== null
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "OK")
                textColor: "white"
                onClicked: root.currentAction()
            }
            SecondaryButton {
                implicitWidth: units.gridUnit * 6
                font.pointSize: theme.defaultFont.pointSize + 1
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Cancel")
                textColor: "white"
                onClicked: root.cancelRequested()
            }
        }
    }
}
