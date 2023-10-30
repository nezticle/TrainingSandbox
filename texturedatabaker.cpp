#include "texturedatabaker.h"
#include <QImage>
#include <QImageWriter>

TextureDataBaker::TextureDataBaker(QObject *parent)
    : QObject{parent}
{

}

void TextureDataBaker::bake(QQuick3DTextureData *textureData, const QString &path)
{
    if (!textureData)
        return;
    if (textureData->depth() > 1)
        return;
    if (textureData->format() != QQuick3DTextureData::RGBA8)
        return;

    const int width = textureData->size().width();
    const int height = textureData->size().height();

    // Create the QImage from the texture data
    QImage image{reinterpret_cast<const uchar *>(textureData->textureData().data()), width, height, QImage::Format_RGBA8888};

    // Save the image to disk
    QImageWriter writer{path};
    writer.write(image);
}
