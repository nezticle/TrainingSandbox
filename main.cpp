#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "dynamicfileshelper.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("TrainingSandbox");
    app.setApplicationDisplayName("Training Sandbox");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("The Qt Company");
    app.setOrganizationDomain("qt.io");

    QQmlApplicationEngine engine;

    // get a handle to the DynamicFilesHelper singleton
    auto dynamicFilesHelper = engine.singletonInstance<DynamicFilesHelper>("Main", "DynamicFilesHelper");

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("TrainingSandbox", "Main");

    return app.exec();
}
