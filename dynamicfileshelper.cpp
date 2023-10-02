#include "dynamicfileshelper.h"

#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QDesktopServices>
#include <QImageReader>
#include <QLibraryInfo>
#include <QProcess>

DynamicFilesHelper::DynamicFilesHelper(QObject *parent)
    : QObject{parent}
{
    m_dataDir = QUrl::fromLocalFile(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QDir::separator() + "data");

    // Get the QMLLS Build Directory
    QDir applicationDirPath(QCoreApplication::applicationDirPath());
#ifdef Q_OS_MACOS
    applicationDirPath.cdUp();
    applicationDirPath.cd("Resources");
#elif Q_OS_IOS
    applicationDirPath.cdUp();
#endif
    if (applicationDirPath.cd("qmlls_data")) {
        m_qmllsBuildDir = QUrl::fromLocalFile(applicationDirPath.absolutePath());
    }

    watchPath(m_dataDir.toLocalFile());
    connect(&m_fileSystemWatcher, &QFileSystemWatcher::directoryChanged, this, &DynamicFilesHelper::onDirectoryChanged);
    connect(&m_fileSystemWatcher, &QFileSystemWatcher::fileChanged, this, &DynamicFilesHelper::onFileChanged);
    updateAvailableFiles();
}

QUrl DynamicFilesHelper::dataDir() const
{
    return m_dataDir;
}

bool DynamicFilesHelper::installStarterTemplates(bool forceUpdate)
{
    // This method copies any files in the data/templates folder to the user's templates folder
    // If any of the files already exist, they are not overwritten unless forceUpdate == true

    // Get the location of the templates distributed with the app
    QDir applicationDirPath(QCoreApplication::applicationDirPath());
#ifdef Q_OS_MACOS
    applicationDirPath.cdUp();
    applicationDirPath.cd("Resources");
#elif Q_OS_IOS
    applicationDirPath.cdUp();
#endif
    if(!applicationDirPath.cd("data")) {
        qDebug() << "No data template directory to install!";
        return false;
    }

    QDir templatesDir(m_dataDir.toLocalFile());

    // Make sure both directories exist first
    if (!applicationDirPath.exists()) {
        qDebug() << applicationDirPath.absolutePath() << "does not exist";
        return false;
    }
    if (!templatesDir.exists()) {
        // This isn't actually an issue, just try and create it
        if (!templatesDir.mkpath(templatesDir.absolutePath())) {
            qDebug() << "Failed to create" << templatesDir.absolutePath();
            return false;
        }
    }

    std::function<bool(const QString &, const QString &, bool)> installTemplates = [&](const QString &sourceDirPath, const QString &destinationDirPath, bool forceUpdate) {
        QDir sourceDir(sourceDirPath);
        QDir destinationDir(destinationDirPath);

        // Recursively copy each file/directory from the application templates folder to the user's templates folder
        // if a file or folder already exists and forceUpdate is false, skip it
        for (const auto &entry : sourceDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks)) {
            if (entry.isDir()) {
                if (!destinationDir.exists(entry.fileName())) {
                    if (!destinationDir.mkdir(entry.fileName()))
                        return false;
                }
                installTemplates(entry.filePath(), destinationDir.filePath(entry.fileName()), forceUpdate);
            } else {
                if (!destinationDir.exists(entry.fileName()) || forceUpdate) {
                    if (!QFile::copy(entry.filePath(), destinationDir.filePath(entry.fileName())))
                        return false;
                }
            }
        }
        return true;
    };

    // Recursively copy each file/directory from the application templates folder to the user's templates folder
    // if a file or folder already exists and forceUpdate is false, skip it
    return installTemplates(applicationDirPath.absolutePath(), templatesDir.absolutePath(), forceUpdate);
}

bool DynamicFilesHelper::watchFile(const QUrl &url)
{
    return m_fileSystemWatcher.addPath(url.toLocalFile());
}

bool DynamicFilesHelper::unwatchFile(const QUrl &url)
{
    return m_fileSystemWatcher.removePath(url.toLocalFile());
}

void DynamicFilesHelper::openTemplateDirectory()
{
    QDesktopServices::openUrl(m_dataDir);
}

void DynamicFilesHelper::onDirectoryChanged(const QString &path)
{
    QStringList oldEntryList = m_currentContents[path];
    const QDir dir(path);

    QStringList newEntryList = dir.entryList(QDir::AllDirs | QDir::Files | QDir::NoDotAndDotDot, QDir::DirsFirst);

    QSet<QString> newEntrySet(newEntryList.begin(), newEntryList.end());
    QSet<QString> oldEntrySet(oldEntryList.begin(), oldEntryList.end());

    // Files that have been added
    QSet<QString> newFilesSet = newEntrySet - oldEntrySet;
    QStringList newFiles = newFilesSet.values();

    // Files that have been removed
    QSet<QString> deletedFilesSet = oldEntrySet - newEntrySet;
    QStringList deleteFiles = deletedFilesSet.values();

    // Update the tracked files for the path
    m_currentContents[path] = newEntryList;

    if (!newFiles.isEmpty() && !deleteFiles.isEmpty()) {
        // A file or directory has been renamed
        if(newFiles.size() == 1 && deleteFiles.size() == 1) {
            const QString oldPath = path + QDir::separator() + deleteFiles.first();
            const QString newPath = path + QDir::separator() + newFiles.first();

            // If a directory was renamed, update the tracked files for the new path
            const QFileInfo oldPathInfo(oldPath);

            if (oldPathInfo.isDir()) {
                m_currentContents[newPath] = m_currentContents[oldPath];
                m_currentContents.remove(oldPath);
                unWatchPath(oldPath);
                watchPath(newPath);
            }

            updateAvailableFiles();
        }
    } else {
        // A file or directory has been created
        if (!newFiles.isEmpty()) {
            for (const auto &file : newFiles) {
                const QFileInfo newPathInfo(path + QDir::separator() + file);
                if (newPathInfo.isDir())
                    watchPath(path + QDir::separator() + file);
            }
            updateAvailableFiles();
        }

        // A file or directory has been deleted
        if (!deleteFiles.isEmpty()) {
            for (const auto &file : deleteFiles) {
                const QFileInfo deletedPathInfo(path + QDir::separator() + file);
                if (deletedPathInfo.isDir())
                    unWatchPath(path + QDir::separator() + file);
                else
                    emit fileDeleted(QUrl::fromLocalFile(path + QDir::separator() + file));
            }
            updateAvailableFiles();
        }
    }
}

void DynamicFilesHelper::updateAvailableFiles()
{
    // Create a list of urls to all tracked files
    m_availableFiles.clear();

    for (const auto &folder : m_currentContents.keys()) {
        const auto &files = m_currentContents[folder];
        for (const auto &file : files) {
            const QFileInfo fileInfo(folder + QDir::separator() + file);
            if (fileInfo.isFile()) {
                const QString simpleFileName = fileInfo.absoluteFilePath().remove(m_dataDir.toLocalFile() + QDir::separator());
                m_availableFiles.insert(QUrl::fromLocalFile(fileInfo.absoluteFilePath()), simpleFileName);
            }
        }
    }

    emit availableFilesChanged();
    emit availableFileNamesChanged();
}

void DynamicFilesHelper::watchPath(const QString &path)
{
    bool success = m_fileSystemWatcher.addPath(path);
    if (success) {
        QFileInfo info(path);
        if (info.isDir()) {
            const QDir directory(path);
            m_currentContents[path] = directory.entryList(QDir::AllDirs | QDir::Files | QDir::NoDotAndDotDot, QDir::DirsFirst);

            // Recursively watch all subdirectories
            const QStringList subdirs = directory.entryList(QDir::AllDirs | QDir::NoDotAndDotDot);
            for (const auto &subdir : subdirs) {
                const QString subpath = path + QDir::separator() + subdir;
                watchPath(subpath);
            }
        }
        updateAvailableFiles();
    }
}

void DynamicFilesHelper::unWatchPath(const QString &path)
{
    m_fileSystemWatcher.removePath(path);

    // also check if we are tracking the contents of a directory
    for (auto it = m_currentContents.constBegin(); it != m_currentContents.constEnd(); ++it) {
        if (it.key() == path) {
            m_currentContents.erase(it);
            break;
        }
    }

    updateAvailableFiles();
}

QList<QUrl> DynamicFilesHelper::availableFiles() const
{
    return m_availableFiles.keys();
}

void DynamicFilesHelper::onFileChanged(const QString &path)
{
    auto url = QUrl::fromLocalFile(path);
    emit fileUpdated(url);
}

QList<QString> DynamicFilesHelper::availableFileNames() const
{
    return m_availableFiles.values();
}

QList<QString> DynamicFilesHelper::imageNameFilters() const
{
    QList<QString> filters;

    QString imageFiles = "Image Files (";
    auto imageReaderFormats = QImageReader::supportedImageFormats();
    for (const auto &format : imageReaderFormats) {
        imageFiles += "*." + format + " ";
    }
    imageFiles += ")";
    filters << imageFiles;

    // ktx, astc supported by QTextureFileReader
    QString textureFiles = "Compressed Textures (*.ktx *.astc)";
    filters << textureFiles;

    // hdr, exr supported by QtQuick3D
    QString hdrFiles = "HDR Files (*.hdr *.exr)";
    filters << hdrFiles;

    return filters;
}

void DynamicFilesHelper::importImages(const QList<QUrl> &urls, const QUrl &currentFile)
{
    // Figure out the target directory
    QDir targetDir;
    if (currentFile.isEmpty()) {
        // if there is no currentFile set, the the target directory is the template directory root
        const auto currentFileString = m_dataDir.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    } else {
        const auto currentFileString = currentFile.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    }
    // if the name of the directory is either images or maps then that is the target directory
    // otherwise create a new directory called images
    if (targetDir.dirName() != "images" || targetDir.dirName() != "maps") {
        targetDir.mkdir("images");
        targetDir.cd("images");
    }

    // Copy all files to the target directory
    for (const auto &url : urls) {
        const auto sourceFile = url.toLocalFile();
        const auto targetFile = targetDir.absoluteFilePath(QFileInfo(sourceFile).fileName());
        QFile::copy(sourceFile, targetFile);
    }
}

void DynamicFilesHelper::importModel(const QUrl &modelLocation, const QUrl &currentFile)
{
    // Figure out the target directory
    QDir targetDir;
    if (currentFile.isEmpty()) {
        // if there is no currentFile set, the the target directory is the template directory root
        const auto currentFileString = m_dataDir.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    } else {
        const auto currentFileString = currentFile.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    }

    // Check if balsam binary is available
    auto qtBinaryPath = QLibraryInfo::path(QLibraryInfo::BinariesPath);
    auto balsamBinaryPath = qtBinaryPath + QDir::separator() + "balsam";
    if (!QFile::exists(balsamBinaryPath)) {
        qWarning() << "Could not find balsam binary at" << balsamBinaryPath;
        return;
    }

    // Run balsam to convert the model
    const auto modelFile = modelLocation.toLocalFile();
    QStringList arguments;
    arguments << "-o" << targetDir.absolutePath() << modelFile;

    QProcess::startDetached(balsamBinaryPath, arguments);
}

void DynamicFilesHelper::openCustomMaterialEditor(const QUrl &currentFile)
{
    // Figure out the target directory
    QDir targetDir;
    if (currentFile.isEmpty()) {
        // if there is no currentFile set, the the target directory is the template directory root
        const auto currentFileString = m_dataDir.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    } else {
        const auto currentFileString = currentFile.toLocalFile();
        targetDir = QFileInfo(currentFileString).absoluteDir();
    }

    // Check if materialeditor binary is available
    auto qtBinaryPath = QLibraryInfo::path(QLibraryInfo::BinariesPath);
    auto materialEditorBinaryPath = qtBinaryPath + QDir::separator() + "materialeditor";
    if (!QFile::exists(materialEditorBinaryPath)) {
        qWarning() << "Could not find materialeditor binary at" << materialEditorBinaryPath;
        return;
    }

    // Run materialeditor
    QStringList arguments;
    arguments << "-p" << targetDir.absolutePath();

    QProcess::startDetached(materialEditorBinaryPath, arguments);
}

QString DynamicFilesHelper::getFileName(const QUrl &url)
{
    QString fileName;
    QFileInfo info(url.toLocalFile());
    if (info.exists()) {
        fileName = info.fileName();
    }

    return fileName;
}

void DynamicFilesHelper::clearComponentCache()
{
    auto engine = qmlEngine(this);
    if (engine) {
        engine->clearComponentCache();
    }
}

void DynamicFilesHelper::trimComponentCache()
{
    auto engine = qmlEngine(this);
    if (engine) {
        engine->trimComponentCache();
    }
}

QUrl DynamicFilesHelper::qmllsBuildDir() const
{
    return m_qmllsBuildDir;
}
