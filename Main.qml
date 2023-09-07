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
                    loader.source = DynamicFilesHelper.availableFiles[dynamicFileComboBox.currentIndex]
                }
            }
            Button {
                text: "Load Current"
                onClicked: {
                    loader.source = codeEditor.currentFile
                }
            }
        }
    }

    Component.onCompleted: {
        let result = DynamicFilesHelper.installStarterTemplates()
        if (result === false)
            console.log("failed to installStarterTemplates")
    }

    SplitView {
        id: splitView
        anchors.fill: parent
        DynamicItemLoader {
            id: loader
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            SplitView.minimumWidth: splitView.width * 0.25
            source: ""
        }

        Item {
            id: toolPage
            SplitView.preferredWidth: splitView.width * 0.5
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            TabBar {
                id: tabBar
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                Layout.fillWidth: true
                TabButton {
                    text: "Editor"
                }
                TabButton {
                    text: "Console"
                }
            }
            StackLayout {
                currentIndex: tabBar.currentIndex
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: tabBar.bottom
                anchors.bottom: parent.bottom

                CodeEditor {
                    id: codeEditor
                    property real editorHeight: 0.5
                    projectFolder: DynamicFilesHelper.dataDir
                }
                ScriptConsoleItem {
                    id: consoleItem
                    property real consoleHeight: 0.5
                }
            }
        }
    }
}
