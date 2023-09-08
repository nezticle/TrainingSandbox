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
            onLoadedInstanceChanged: ScriptContext.expose(loadedInstance, "loadedInstance")
        }

        SplitView {
            id: toolsSplitView
            SplitView.preferredWidth: splitView.width * 0.5
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            orientation: Qt.Vertical
            CodeEditor {
                id: codeEditor
                projectFolder: DynamicFilesHelper.dataDir
                SplitView.fillHeight: true
                SplitView.fillWidth: true
                SplitView.preferredHeight: toolsSplitView.height * 0.8
            }
            ScriptConsoleItem {
                id: consoleItem
                SplitView.preferredHeight: toolsSplitView.height * 0.2
                SplitView.fillHeight: true
                SplitView.fillWidth: true
            }
        }
    }
}
