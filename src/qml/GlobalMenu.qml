/**
 * SPDX-FileCopyrightText: 2021 by Alexander Stippich <a.stippich@gmx.net>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.7
import Qt.labs.platform 1.1

MenuBar {

    property var newDocAction
    property var saveDocAction
    property var printAction
    property var quitAction
    property var scanAction
    property var cancelAction
    property var showOptionsAction
    property var allOptionsAction
    property var reselectDevicesAction
    property var showAboutAction

    Menu {
        title: i18nc("menu category", "File")

        MenuItem {
            text: newDocAction.text
            iconName: newDocAction.icon.name
            onTriggered: newDocAction.trigger()
            enabled: newDocAction.enabled
        }

        MenuItem {
            text: saveDocAction.text
            iconName: saveDocAction.icon.name
            onTriggered: saveDocAction.trigger()
            enabled: saveDocAction.enabled
        }

        MenuItem {
            text: printAction.text
            iconName: printAction.icon.name
            onTriggered: printAction.trigger()
            enabled: printAction.enabled
        }

        MenuSeparator {
        }

        MenuItem {
            text: quitAction.text
            iconName: quitAction.icon.name
            onTriggered: quitAction.trigger()
            enabled: quitAction.enabled
        }
    }

    Menu {
        title: i18nc("menu category", "Scan")

        MenuItem {
            text: scanAction.text
            iconName: scanAction.icon.name
            onTriggered: scanAction.trigger()
            enabled: scanAction.enabled
        }

        MenuItem {
            text: cancelAction.text
            iconName: cancelAction.icon.name
            onTriggered: cancelAction.trigger()
            enabled: cancelAction.enabled
        }
        
        MenuSeparator {
        }

        MenuItem {
            text: showOptionsAction.text
            iconName: showOptionsAction.icon.name
            onTriggered: showOptionsAction.trigger()
            enabled: showOptionsAction.enabled
            checkable: showOptionsAction.checkable
            checked: showOptionsAction.checked
        }
        
        MenuItem {
            text: allOptionsAction.text
            iconName: allOptionsAction.icon.name
            onTriggered: allOptionsAction.trigger()
            enabled: allOptionsAction.enabled
            checkable: allOptionsAction.checkable
            checked: allOptionsAction.checked
        }

        MenuSeparator {
        }
        
        MenuItem {
            text: reselectDevicesAction.text
            iconName: reselectDevicesAction.icon.name
            onTriggered: reselectDevicesAction.trigger()
            enabled: reselectDevicesAction.enabled
        }
    }

    Menu {
        title: i18nc("menu category", "Help")

        MenuItem {
            text: showAboutAction.text
            iconName: showAboutAction.icon.name
            onTriggered: showAboutAction.trigger()
            enabled: showAboutAction.enabled
        }
    }
}
