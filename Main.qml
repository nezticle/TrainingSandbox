import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScriptConsole
import CodeEditor

ApplicationWindow {
    width: 1280
    height: 720
    visible: true
    title: qsTr("Training Sandbox")

    header: ToolBar {
        RowLayout {
            ComboBox {
                id: dynamicFileComboBox
                Layout.fillWidth: true
                model: DynamicFilesHelper.availableFileNames
            }
            Button {
                text: "Load"
                onClicked: {
                    //loader.source = DynamicFilesHelper.dataDir + '/' + DynamicFilesHelper.availableFiles[dynamicFileComboBox.currentIndex]
                    loader.source = DynamicFilesHelper.availableFiles[dynamicFileComboBox.currentIndex]
                }
            }
        }
    }

    Component.onCompleted: {
        let result = DynamicFilesHelper.installStarterTemplates()
        if (result === false)
            console.log("failed to installStarterTemplates")
    }

    DynamicItemLoader {
        id: loader
        anchors.fill: parent
        source: ""
    }

    CodeEditor {
        id: codeEditor
        property real editorHeight: 0.5
        anchors.right: parent.right
        anchors.left: parent.left
        height: parent.height * editorHeight

        projectFolder: DynamicFilesHelper.dataDir

        state: "hidden"

        Shortcut {
            id: editorShortcut
            sequence: "F10"
            onActivated: {
                if (codeEditor.state === 'hidden') {
                    codeEditor.state = 'visible'
                } else {
                    codeEditor.state = 'hidden'
                }
            }
        }

        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    codeEditor.y: codeEditor.parent.height + codeEditor.height
                    codeEditor.focus: false
                }
            },
            State {
                name: "visible"
                PropertyChanges {
                    codeEditor.y: codeEditor.parent.height - codeEditor.height
                    codeEditor.focus: true
                }
            }
        ]

        transitions: [
            Transition {
                from: "hidden"
                to: "visible"
                reversible: true
                NumberAnimation { properties: "y"; duration: 200 }
            }
        ]
    }

    ScriptConsoleItem {
        id: consoleItem
        property real consoleHeight: 0.5

        anchors.right: parent.right
        anchors.left: parent.left
        height: parent.height * consoleHeight

        state: "hidden"

        Shortcut {
            id: consoleShortcut
            sequence: "F12"
            onActivated: {
                if (consoleItem.state === 'hidden') {
                    consoleItem.state = 'visible'
                } else {
                    consoleItem.state = 'hidden'
                }
            }
        }

        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    consoleItem.y: -height
                    consoleItem.focus: false
                }
            },
            State {
                name: "visible"
                PropertyChanges {
                    consoleItem.y: 0
                    consoleItem.focus: true
                }
            }
        ]

        transitions: [
            Transition {
                from: "hidden"
                to: "visible"
                reversible: true
                NumberAnimation { properties: "y"; duration: 200 }
            }
        ]
    }
}
