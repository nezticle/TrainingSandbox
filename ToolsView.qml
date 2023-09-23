import QtQuick
import QtQuick.Controls
import ScriptConsole
import CodeEditor

SplitView {
    id: toolsSplitView
    readonly property alias codeEditor: codeEditor
    orientation: Qt.Vertical
    CodeEditor {
        id: codeEditor
        projectFolder: DynamicFilesHelper.dataDir
        SplitView.fillHeight: true
        SplitView.fillWidth: true
        SplitView.minimumHeight: 128
        SplitView.preferredHeight: toolsSplitView.height * 0.8
    }
    ScriptConsoleItem {
        id: consoleItem
        SplitView.preferredHeight: toolsSplitView.height * 0.2
        SplitView.minimumHeight: 48
        SplitView.fillWidth: true
    }
}
