// Copyright (C) 2026 Qt Group.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtCore
import QtQuick.Controls
import ScriptConsole
import CodeEditor

SplitView {
    id: toolsSplitView
    readonly property alias codeEditor: codeEditor
    orientation: Qt.Vertical

    Component.onCompleted: {
        toolsSplitView.restoreState(settings.value("ui/toolsSplitView"))
    }

    Component.onDestruction: {
        settings.setValue("ui/toolsSplitView", toolsSplitView.saveState())
    }

    Settings {
        id: settings
    }

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
