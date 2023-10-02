#ifndef DYNAMICFILESHELPER_H
#define DYNAMICFILESHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QFileSystemWatcher>

class DynamicFilesHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl dataDir READ dataDir CONSTANT FINAL)
    Q_PROPERTY(QUrl qmllsBuildDir READ qmllsBuildDir CONSTANT FINAL)
    Q_PROPERTY(QList<QUrl> availableFiles READ availableFiles NOTIFY availableFilesChanged FINAL)
    Q_PROPERTY(QList<QString> availableFileNames READ availableFileNames NOTIFY availableFileNamesChanged FINAL)
    QML_SINGLETON
    QML_ELEMENT
public:
    explicit DynamicFilesHelper(QObject *parent = nullptr);

    QUrl dataDir() const;

    Q_INVOKABLE bool installStarterTemplates(bool forceUpdate = false);
    Q_INVOKABLE bool watchFile(const QUrl &url);
    Q_INVOKABLE bool unwatchFile(const QUrl &url);

    Q_INVOKABLE void openTemplateDirectory();

    QList<QUrl> availableFiles() const;
    QList<QString> availableFileNames() const;

    Q_INVOKABLE QList<QString> imageNameFilters() const;
    Q_INVOKABLE void importImages(const QList<QUrl> &urls, const QUrl &currentFile);
    Q_INVOKABLE void importModel(const QUrl &modelLocation, const QUrl &currentFile);
    Q_INVOKABLE void openCustomMaterialEditor(const QUrl &currentFile);

    Q_INVOKABLE QString getFileName(const QUrl &url);

    Q_INVOKABLE void clearComponentCache();
    Q_INVOKABLE void trimComponentCache();


    QUrl qmllsBuildDir() const;

signals:
    void availableFilesChanged();
    void fileUpdated(const QUrl &url);
    void fileDeleted(const QUrl &url);

    void availableFileNamesChanged();

private slots:
    void onFileChanged(const QString &path);
    void onDirectoryChanged(const QString &path);
private:
    void updateAvailableFiles();
    void watchPath(const QString &path);
    void unWatchPath(const QString &path);
    QUrl m_dataDir;
    QFileSystemWatcher m_fileSystemWatcher;
    QHash<QString, QStringList> m_currentContents;
    QHash<QUrl, QString> m_availableFiles;
    QUrl m_qmllsBuildDir;
};

#endif // DYNAMICFILESHELPER_H
