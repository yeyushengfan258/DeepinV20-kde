/*
 *   Copyright 2020 Alex Woroschilow <alex.woroschilow@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.8
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root
    property alias text: label.text
    property alias textColor: label.color

    property alias containsMouse: mouseArea.containsMouse
    property alias font: label.font
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    signal clicked

    activeFocusOnTab: true

    opacity: activeFocus || containsMouse ? 1 : 0.85
        Behavior on opacity {
            PropertyAnimation { // OpacityAnimator makes it turn black at random intervals
                duration: units.longDuration * 2
                easing.type: Easing.InOutQuad
            }
    }

    Rectangle {
        id: backgroundRect

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        radius: 100
        width: label.font.pointSize * 8
        height: label.font.pointSize * 3
        color: "white"
        opacity: 0.35
    }


    PlasmaComponents.Label {
        id: label
        font.pointSize: theme.defaultFont.pointSize + 1
        anchors {
            horizontalCenter: backgroundRect.horizontalCenter
            verticalCenter: backgroundRect.verticalCenter
        }
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? PlasmaCore.ColorScope.backgroundColor : "transparent" //no outline, doesn't matter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        font.underline: root.activeFocus
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        onClicked: root.clicked()
        anchors.fill: parent
    }

    Keys.onEnterPressed: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    Accessible.onPressAction: clicked()
    Accessible.role: Accessible.Button
    Accessible.name: label.text
}
