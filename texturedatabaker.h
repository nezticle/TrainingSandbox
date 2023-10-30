#ifndef TEXTUREDATABAKER_H
#define TEXTUREDATABAKER_H

#include <QObject>
#include <QQmlEngine>

#include <QtQuick3D/QQuick3DTextureData>

class TextureDataBaker : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit TextureDataBaker(QObject *parent = nullptr);

    Q_INVOKABLE void bake(QQuick3DTextureData *textureData, const QString &path);

};

#endif // TEXTUREDATABAKER_H
