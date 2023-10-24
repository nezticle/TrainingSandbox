import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import ScriptConsole
import CodeEditor

ApplicationWindow {
    id: window
    width: 1280
    height: 720
    visible: true
    title: generateWindowTitle(loader.source)

    Settings {
        id: settings
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
    }

    Component.onCompleted: {
        splitView.restoreState(settings.value("ui/splitview"))
    }


    Component.onDestruction: {
        settings.setValue("ui/splitview", splitView.saveState())
    }

    function generateWindowTitle(source: url) : string {
        let title = qsTr("Training Sandbox")
        if (source != "") {
            title += " - " + DynamicFilesHelper.getFileName(source)
        }
        return title
    }

    Action {
        id: explicitReloadAction
        text: qsTr("Reload")
        shortcut: "F5"
        enabled: loader.source != ""
        onTriggered: {
            loader.explicitReload()
        }
    }

    Action {
        id: loadCurrentAction
        text: qsTr("Load Current")
        shortcut: "F4"
        enabled: toolsView.codeEditor.currentFile != ""
        onTriggered: {
            loader.source = toolsView.codeEditor.currentFile
        }
    }

    header: ToolBar {
        RowLayout {
            width: parent.width
            ToolButton {
                text: "\ue01a"
                font.family: iconFont.font.family
                font.pointSize: 24
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Load Current (F4)")
                action: loadCurrentAction
            }
            ToolButton {
                text: "Z"
                font.family: iconFont.font.family
                font.pointSize: 24
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Force Reload (F5)")
                action: explicitReloadAction
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
            ToolButton {
                id: customMaterialEditorButton
                font.family: iconFont.font.family
                font.pointSize: 24
                text: "L"
                hoverEnabled: true
                ToolTip.delay: 500
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Custom Material Editor")
                onClicked: {
                    DynamicFilesHelper.openCustomMaterialEditor(toolsView.codeEditor.currentFile)
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

    SplitView {
        id: splitView
        anchors.fill: parent
        ToolsView {
            id: toolsView
            SplitView.fillHeight: true
            SplitView.preferredWidth: splitView.width * 0.5
            visible: toolViewButton.checked
        }

        Item {
            id: dynamicContentArea
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            SplitView.minimumWidth: splitView.width * 0.25
            DynamicItemLoader {
                id: loader
                anchors.fill: parent
                source: ""
                onLoadedInstanceChanged: {
                    ScriptContext.expose(loader.loadedInstance, "loadedInstance")
                    ScriptContext.expose(loader.screenshot, "screenshot")
                }

                function screenshot(filename: string) {
                    loader.grabToImage(function(result) {
                        result.saveToFile(filename)
                    })
                }
            }

            Image {
                visible: loader.source == ""
                source: "sandbox.jpg"
                fillMode: Image.Tile
                anchors.fill: parent

                Text {
                    anchors.centerIn: parent
                    text: qsTr("No content loaded, select a file and load it.")
                    font.pointSize: 24
                    color: "white"
                    style: Text.Outline
                    styleColor: "black"
                }
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
            DynamicFilesHelper.importImages(imageFileImportDialog.selectedFiles, toolsView.codeEditor.currentFile)
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
            DynamicFilesHelper.importModel(assetFileImportDialog.selectedFile, toolsView.codeEditor.currentFile)
        }
    }
}
