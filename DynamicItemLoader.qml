import QtQuick
import ScriptConsole

Item {
    id: loaderRoot
    property url source: ""
    property var properties: ({})
    readonly property alias loadedInstance: loaderData.objectInstance

    onSourceChanged: {
        if (loaderData.componentUrl != "") {
            // Stop monitoring the current file
            DynamicFilesHelper.unwatchFile(loaderData.componentUrl)
        }

        if (source === "") {
            loaderData.cleanup()
        } else {
            _loadSource();
        }
    }

    function explicitReload() {
        // Do nothing if there was nothing to load
        if (source === "")
            return;

        loaderData.cleanup();
        _loadSource();
    }

    function _loadSource() {
        // make sure source is prefixed with the data dir location
        let realSource = source;
        if (!realSource.toString().startsWith(DynamicFilesHelper.dataDir)) {
            realSource = DynamicFilesHelper.dataDir + "/" + realSource
        }
        // start monitoring the new file
        let success = DynamicFilesHelper.watchFile(realSource)
        success = loaderData.tryToCreateComponent(realSource)
        if (success === true) {
            loaderData.updateObjectInstance()
        } else {
            ScriptContext.logError(loaderData.errorString)
        }
    }

    QtObject {
        id: loaderData
        property Component component: null
        property url componentUrl: ""
        property string errorString: ""
        property var objectInstance: null
        property var revisionTable: ({}) // source: revisionNumber

        function getRevisionNumber(source : url) : int {
            if (loaderData.revisionTable.hasOwnProperty(source)) {
                loaderData.revisionTable[source] = revisionTable[source] + 1
            } else {
                loaderData.revisionTable[source] = 0
            }
            return loaderData.revisionTable[source]
        }

        function cleanup() {
            if (loaderData.objectInstance != null)
                loaderData.objectInstance.destroy()
            loaderData.objectInstance = null
            loaderData.component = null
            loaderData.componentUrl = ""
            errorString = ""
        }

        function tryToCreateComponent(source : url) : bool {
            if (source === "")
                return false
            const sourceUrl = new URL(source)
            const avoidComponentCacheUrl = sourceUrl.href + "?" + 'r' + getRevisionNumber(sourceUrl.href)
            let newComponent = Qt.createComponent(avoidComponentCacheUrl)
            if (newComponent.status === Component.Ready) {
                loaderData.component = newComponent
                loaderData.componentUrl = source
                errorString = ""
                return true;
            } else if (newComponent.status === Component.Error) {
                errorString = newComponent.errorString()
                return false;
            }
        }

        function updateObjectInstance() {
            if (loaderData.component == null)
                return

            let newObject = loaderData.component.createObject(loaderRoot, loaderRoot.properties)
            if (newObject === null)
                return

            if (loaderData.objectInstance != null)
                loaderData.objectInstance.destroy()

            loaderData.objectInstance = newObject
        }
    }
    Connections {
        target: DynamicFilesHelper
        function onFileUpdated(url) {
            let fileUpdated = new URL(url);
            if (loaderData.componentUrl === "")
                return
            let currentFile = new URL(loaderData.componentUrl);

            if (fileUpdated.href === currentFile.href) {
                // We need to update the component and object instance
                let success = loaderData.tryToCreateComponent(url)
                if (success === true) {
                    loaderData.updateObjectInstance()
                } else {
                    ScriptContext.logError(loaderData.errorString)
                }
            }
        }
        function onFileDeleted(url) {
            let fileDeleted = new URL(url);
            if (loaderData.componentUrl === "")
                return
            let currentFile = new URL(loaderData.componentUrl);
            if (fileDeleted.href === currentFile.href) {
                console.log("Current component source file was deleted");
            }
        }
    }
}
