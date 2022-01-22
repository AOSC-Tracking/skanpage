/**
 * SPDX-FileCopyrightText: 2021 by Alexander Stippich <a.stippich@gmx.net>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "DocumentSaver.h"

#include <QFileInfo>
#include <QPainter>
#include <QPdfWriter>
#include <QUrl>
#include <QTransform>
#include <QtConcurrent>

#include <KLocalizedString>

#include "skanpage_debug.h"

DocumentSaver::DocumentSaver(QObject *parent)
    : QObject(parent)
{
}

DocumentSaver::~DocumentSaver()
{
}

void DocumentSaver::saveDocument(const QUrl &fileUrl, const SkanpageUtils::DocumentPages &document, const FileType type)
{
    if (fileUrl.isEmpty() || document.isEmpty()) {
        Q_EMIT showUserMessage(SkanpageUtils::ErrorMessage, i18n("Nothing to save."));
        return;
    }
    if (m_future.isRunning()) {
        Q_EMIT showUserMessage(SkanpageUtils::ErrorMessage, i18n("Saving still in progress."));
        return;
    }
    qCDebug(SKANPAGE_LOG) << QStringLiteral("Saving document to") << fileUrl;

    m_future = QtConcurrent::run(this, &DocumentSaver::save, fileUrl, document, type);
}

void DocumentSaver::save(const QUrl &fileUrl, const SkanpageUtils::DocumentPages &document, const FileType type)
{
    const QFileInfo &fileInfo = QFileInfo(fileUrl.toLocalFile());
    const QString &fileSuffix = fileInfo.suffix();

    QUrl saveUrl;
    if (fileSuffix.isEmpty()) {
        saveUrl = QUrl::fromLocalFile(fileUrl.toLocalFile() + QStringLiteral(".pdf"));
        qCDebug(SKANPAGE_LOG) << QStringLiteral("File suffix is empty. Automatically setting format to PDF.");
    } else {
        saveUrl = fileUrl;
        qCDebug(SKANPAGE_LOG) << QStringLiteral("Selected file suffix is") << fileSuffix;
    }

    if (fileSuffix == QLatin1String("pdf") || fileSuffix.isEmpty()) {
        savePDF(saveUrl, document, type);
    } else {
        saveImage(fileInfo, document, type);
    }
}

void DocumentSaver::savePDF(const QUrl &fileUrl, const SkanpageUtils::DocumentPages &document, const FileType type)
{
    QPdfWriter writer(fileUrl.toLocalFile());
    QPainter painter;
    int rotationAngle;

    for (int i = 0; i < document.count(); ++i) {
        writer.setResolution(document.at(i).dpi);
        writer.setPageSize(document.at(i).pageSize);
        writer.setPageMargins(QMarginsF(0, 0, 0, 0));
        rotationAngle = document.at(i).rotationAngle;
        if (rotationAngle == 90 || rotationAngle == 270) {
            writer.setPageOrientation(QPageLayout::Landscape);
        } else {
            writer.setPageOrientation(QPageLayout::Portrait);
        }
        writer.newPage();

        QTransform transformation;
        if (rotationAngle != 0) {
            transformation.translate(writer.width()/2, writer.height()/2);
            transformation.rotate(rotationAngle);
            transformation.translate(-writer.width()/2, -writer.height()/2);
        }
        if (rotationAngle == 90 || rotationAngle == 270) {
            //strange that this is needed and Qt does not do this automatically
            transformation.translate((writer.width()-writer.height())/2, (writer.height()-writer.width())/2);
        }

        if (i == 0) {
            painter.begin(&writer);
        }

        painter.setTransform(transformation);
        QImage pageImage(document.at(i).temporaryFile->fileName());
        painter.drawImage(QPoint(0, 0), pageImage, pageImage.rect());
    }
    Q_EMIT showUserMessage(SkanpageUtils::InformationMessage, i18n("Document saved as PDF."));
    if (type == EntireDocument) {
        Q_EMIT fileSaved({fileUrl}, document);
    }
}

void DocumentSaver::saveImage(const QFileInfo &fileInfo, const SkanpageUtils::DocumentPages &document, const FileType type)
{
    const int count = document.count();
    QImage pageImage;
    QString fileName;
    QList<QUrl> fileUrls;

    bool success = true;
    if (count == 1) {
        pageImage.load(document.at(0).temporaryFile->fileName());
        fileName = fileInfo.absoluteFilePath();
        const int rotationAngle = document.at(0).rotationAngle;
        if (rotationAngle != 0) {
            pageImage = pageImage.transformed(QTransform().rotate(rotationAngle));
        }
        success = pageImage.save(fileName, fileInfo.suffix().toLocal8Bit().constData());
        fileUrls.append(QUrl::fromLocalFile(fileName));
    } else {
        fileUrls.reserve(count);
        for (int i = 0; i < count; ++i) {
            pageImage.load(document.at(i).temporaryFile->fileName());
            const int rotationAngle = document.at(i).rotationAngle;
            if (rotationAngle != 0) {
                pageImage = pageImage.transformed(QTransform().rotate(rotationAngle));
            }
            fileName =
                QStringLiteral("%1/%2%3.%4").arg(fileInfo.absolutePath(), fileInfo.baseName(), QLocale().toString(i).rightJustified(4, QLatin1Char('0')), fileInfo.suffix());
            if(!pageImage.save(fileName, fileInfo.suffix().toLocal8Bit().constData())) {
                success = false;
            }
            fileUrls.append(QUrl::fromLocalFile(fileName));
        }
    }

    if (success) {
        Q_EMIT showUserMessage(SkanpageUtils::InformationMessage, i18n("Document saved as image."));
        if (type == EntireDocument) {
            Q_EMIT fileSaved(fileUrls, document);
        }
    } else {
        Q_EMIT showUserMessage(SkanpageUtils::ErrorMessage, i18n("Failed to save document as image."));
    }
    
}

void DocumentSaver::saveNewPageTemporary(const int pageID, const QImage &image)
{
    QtConcurrent::run(this, &DocumentSaver::saveNewPage, pageID, image);
}

void DocumentSaver::saveNewPage(const int pageID, const QImage &image)
{
    const QPageSize pageSize = QPageSize(QSizeF(image.width() * 1000.0 / image.dotsPerMeterX() , image.height() * 1000.0 / image.dotsPerMeterY()), QPageSize::Millimeter);
    const int dpi = qRound(image.dotsPerMeterX() / 1000.0 * 25.4);
    QTemporaryFile *tempImageFile = new QTemporaryFile();
    tempImageFile->open();
    if (image.save(tempImageFile, "PNG")) {
        qCDebug(SKANPAGE_LOG) << "Saved new image to temporary file.";
    } else {
        qCDebug(SKANPAGE_LOG) << "Saving new image to temporary file failed!";
        Q_EMIT showUserMessage(SkanpageUtils::ErrorMessage, i18n("Failed to save image"));
    }
    qCDebug(SKANPAGE_LOG) << image << tempImageFile << "with page size" << pageSize << "and resolution of" << dpi << "dpi";
    tempImageFile->close();
    Q_EMIT pageTemporarilySaved(pageID, {std::shared_ptr<QTemporaryFile>(tempImageFile), pageSize, dpi});
}
