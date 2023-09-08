import QtQuick
import QtQuick3D
import ScriptConsole

Node {
    id: loaderRoot
    property url source: ""
    property var properties: ({})

    onSourceChanged: {
        if (loaderData.componentUrl != "") {
            // Stop monitoring the current file
            DynamicFilesHelper.unwatchFile(loaderData.componentUrl)
        }

        if (source === "") {
            loaderData.cleanup()
        } else {
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
    }

    QtObject {
        id: loaderData
        property Component component: null
        property url componentUrl: ""
        property string errorString: ""
        property var objectInstance: null

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
            const avoidComponentCacheUrl = source + "?" + Math.random()
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
            let currentFile = new URL(loaderData.componentUrl);
            if (fileDeleted.href === currentFile.href) {
                console.log("Current component source file was deleted");
            }
        }
    }
}
