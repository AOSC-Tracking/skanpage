/**
 * SPDX-FileCopyrightText: 2015 by Kåre Särs <kare.sars@iki .fi>
 * SPDX-FileCopyrightText: 2021 by Alexander Stippich <a.stippich@gmx.net>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.7
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.3
import Qt.labs.settings 1.0

import org.kde.kirigami 2.19 as Kirigami
import org.kde.skanpage 1.0

ApplicationWindow {
    id: mainWindow

    visible: true

    title: i18nc("document title: app title", "%1 ― Skanpage", mainView.name)

    width: persistentSettings.width
    height: persistentSettings.height
    x: persistentSettings.x
    y: persistentSettings.y

    minimumWidth: mainToolBar.implicitWidth
    minimumHeight: 400

    Settings {
        id: persistentSettings

        property int x: 0
        property int y: 0
        property int width: 950
        property int height: 550
        property var splitViewState
        property bool showOptions: true
        property bool showAllOptions: false
    }

    Connections {
        target: Qt.application

        function onAboutToQuit() {
            persistentSettings.x = mainWindow.x
            persistentSettings.y = mainWindow.y
            persistentSettings.width = mainWindow.width
            persistentSettings.height = mainWindow.height
            persistentSettings.splitViewState = mainView.splitView.saveState()
            persistentSettings.showOptions = mainView.showOptions
            persistentSettings.showAllOptions = allOptionsAction.checked
        }
    }

    Connections {
        target: skanpage

        function onNewUserMessage(level, message) {
            errorMessage.text = message
            if (level == SkanpageUtils.ErrorMessage) {
                errorMessage.type = Kirigami.MessageType.Error
            } else {
                errorMessage.type = Kirigami.MessageType.Information
            }
            labelWidth.text = message
            errorMessage.visible = true
            hideNotificationTimer.start()
        }
    }

    Action {
        id: newDocAction
        icon.name: "edit-delete-remove"
        text: i18n("Discard All")
        shortcut: StandardKey.New
        enabled: skanpage.documentModel.count !== 0
        onTriggered: skanpage.documentModel.clearData()
    }

    Action {
        id: saveDocAction
        icon.name: "document-save"
        text: i18n("Save All")
        shortcut: StandardKey.Save
        enabled: skanpage.documentModel.count !== 0
        onTriggered: saveFileDialog.open()
    }

    Action {
        id: scanAction
        icon.name: "document-scan"
        text: i18n("Scan")
        shortcut: "SPACE"
        enabled: skanpage.applicationState == Skanpage.ReadyForScan
        onTriggered: skanpage.startScan()
    }

    Action {
        id: cancelAction
        icon.name: "dialog-cancel"
        text: i18n("Cancel")
        shortcut: "Esc"
        enabled: skanpage.applicationState == Skanpage.ScanInProgress
        onTriggered: skanpage.cancelScan()
    }

    Action {
        id: allOptionsAction
        icon.name: "view-more-symbolic"
        text: i18n("Show More")
        shortcut: "CTRL+SPACE"
        checkable: true
        checked: persistentSettings.showAllOptions
        onTriggered: skanpage.optionsModel.showAllOptions(checked)
    }

    Action {
        id: showOptionsAction
        icon.name: "configure"
        text: i18n("Show Scanner Options")
        onTriggered: mainView.showOptions = !mainView.showOptions
    }

    Action {
        id: printAction
        icon.name: "document-print"
        text: i18n("Print")
        shortcut: StandardKey.Print
        enabled: skanpage.documentModel.count !== 0
        onTriggered: skanpage.documentModel.print()
    }

    Action {
        id: showAboutAction
        icon.name: "skanpage"
        text: i18n("About Skanpage")
        onTriggered: aboutWindow.show()
    }

    Action {
        id: reselectDevicesAction
        icon.name: "view-refresh"
        text: i18n("Reselect Scanner")
        onTriggered: skanpage.reloadDevicesList()
        enabled: skanpage.applicationState == Skanpage.ReadyForScan
    }
    
    Action {
        id: quitAction
        icon.name: "window-close"
        text: i18n("Quit")
        shortcut: StandardKey.Quit
        onTriggered: Qt.quit()
    }

    Kirigami.InlineMessage {
        id: errorMessage
        width: labelWidth.width + Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2
        height: Math.max(labelWidth.height, Kirigami.Units.iconSizes.medium) + Kirigami.Units.largeSpacing
        z: 2

        anchors {
            top: parent.top
            topMargin: mainToolBar.height + Kirigami.Units.largeSpacing
            horizontalCenter: parent.horizontalCenter
        }

        Timer {
            id: hideNotificationTimer
            interval: 5000
            onTriggered: errorMessage.visible = false
        }

        TextMetrics {
            id: labelWidth
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent

        spacing: 0

        ToolBar {
            id: mainToolBar
            Layout.fillWidth: true

            RowLayout {
                id: toolbarRow
                anchors.fill: parent
                spacing: 0

                Item {

                    implicitWidth: Math.max(children[0].width, children[1].width)
                    implicitHeight: Math.max(children[0].height, children[1].height)

                    ToolButton {
                        anchors.fill: parent
                        action: scanAction
                        visible: skanpage.applicationState !== Skanpage.ScanInProgress
                    }

                    ToolButton {
                        anchors.fill: parent
                        action: cancelAction
                        visible: skanpage.applicationState === Skanpage.ScanInProgress
                    }
                }

                ToolButton {
                    action: saveDocAction
                }

                ToolButton {
                    action: newDocAction
                }

                ToolButton {
                    action: printAction
                }

                Item {
                    id: toolbarSpacer
                    Layout.fillWidth: true
                }

                ToolButton {
                    action: showOptionsAction
                    visible: skanpage.applicationState === Skanpage.ReadyForScan || skanpage.applicationState === Skanpage.ScanInProgress
                    checkable: true
                    checked: mainView.showOptions
                }

                ToolButton {
                    action: showAboutAction
                }
            }
        }

        ContentView {
            id: mainView

            showOptions: persistentSettings.showOptions
            showAllOptions: persistentSettings.showAllOptions
            visible: skanpage.applicationState === Skanpage.ReadyForScan || skanpage.applicationState === Skanpage.ScanInProgress

            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true

            onSaveSinglePage: {
                saveFileDialog.pageNumbers.push(pageNumber)
                saveFileDialog.open()
            }

            Component.onCompleted: {
                mainView.splitView.restoreState(persistentSettings.splitViewState)
            }
        }

        DevicesView {
            id: devicesView

            visible: skanpage.applicationState != Skanpage.ReadyForScan && skanpage.applicationState != Skanpage.ScanInProgress 

            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
        }
    }

    Window {
        id: aboutWindow

        title: i18n("About Skanpage")
        color: Kirigami.Theme.backgroundColor

        flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint
            | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint

        minimumWidth: 600
        minimumHeight: 500

        Kirigami.AboutItem {
            aboutData: _aboutData
            anchors.fill: parent
        }
    }

    FileDialog {
        id: saveFileDialog

        property var pageNumbers: []

        folder: shortcuts.documents
        selectExisting: false
        selectMultiple: false
        nameFilters: skanpage.formatModel.formatFilter()
        onAccepted: {
            skanpage.documentModel.save(fileUrl, pageNumbers)
            pageNumbers = []
        }
        onRejected: pageNumbers = []
    }
    
    GlobalMenu {
        
    }
    
    Component.onCompleted: {
        skanpage.optionsModel.showAllOptions(persistentSettings.showAllOptions)
    }
}
