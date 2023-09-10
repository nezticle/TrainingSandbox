import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ScriptConsole
import CodeEditor

ApplicationWindow {
    width: 1280
    height: 720
    visible: true
    title: qsTr("Training Sandbox")

    header: ToolBar {
        RowLayout {
            width: parent.width
            Button {
                text: "Load Current"
                onClicked: {
                    loader.source = codeEditor.currentFile
                }
            }
            Item {
                //spacer
                Layout.fillWidth: true
            }
            ToolSeparator {

            }

            ToolButton {
                id: openTemplateDirButton
                font.family: iconFont.font.family
                font.pointSize: 24
                text: "{"
                onClicked: {
                    DynamicFilesHelper.openTemplateDirectory();
                }
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Browse Template Directory")
            }
            ToolButton {
                id: importTexturesButton
                font.family: iconFont.font.family
                font.pointSize: 24
                text: "\ue032"
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Import Texures/Images")
                onClicked: {
                    imageFileImportDialog.open()
                }
            }
            ToolButton {
                id: importAssetsButton
                font.family: iconFont.font.family
                font.pointSize: 24
                text: "<"
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Import Models (balsam)")
                onClicked: {
                    assetFileImportDialog.open()
                }
            }

            ToolSeparator {

            }

            ToolButton {
                id: toolViewButton
                font.family: iconFont.font.family
                font.pointSize: 24
                text: "y"
                checkable: true
                checked: true
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Show/Hide Tools")
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
            visible: toolViewButton.checked
            SplitView.preferredWidth: splitView.width * 0.5
            SplitView.fillHeight: true
            SplitView.fillWidth: true
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
                SplitView.fillHeight: true
                SplitView.fillWidth: true
            }
        }
    }

    FontLoader {
        id: iconFont
        source: "dripicons-v2.ttf"
    }

    FileDialog {
        id: imageFileImportDialog
        title: qsTr("Import Images")
        fileMode: FileDialog.OpenFiles
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: DynamicFilesHelper.imageNameFilters()
        onAccepted: {
            // images are imported relative to the current file
            DynamicFilesHelper.importImages(imageFileImportDialog.selectedFiles, codeEditor.currentFile)
        }
    }

    FileDialog {
        id: assetFileImportDialog
        title: qsTr("Import Model")
        fileMode: FileDialog.OpenFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        nameFilters: ["Model Files (*.gltf *.glb *.obj *.dae *.stl *.fbx)"]
        onAccepted: {
            // images are imported relative to the current file
            DynamicFilesHelper.importModel(assetFileImportDialog.selectedFile, codeEditor.currentFile)
        }
    }
}
