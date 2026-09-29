//AppLib бибилиотека приложения
//описываем UDT - пользовательские типы данных

#ifndef APPLIB_H
#define APPLIB_H

#include <QObject>
#include <QOperatingSystemVersion>
#include <QSysInfo>
#include <QJniObject>
#include <QSettings>
#include <QStandardPaths>
#include <QDateTime>
#include <openssl/aes.h>
#include "version/version.h"

class AppLib : public QObject
{
    Q_OBJECT

public:
    explicit AppLib(QObject *parent = nullptr);
    ~AppLib();

private:

public:
    /* getterts */
    static QString getOSVersionString();
    static QString getOpenSSLVersionString();
    static QString getAndroidDeviceInfo();
    static void saveSettings(const QVariantMap &map);
    static QVariantMap loadSettings();
    static QString getHostName() { return QSysInfo::machineHostName(); }
    static QString getAppVersion() { return PROJECT_VERSION_FULL; }

};

#endif // APPLIB_H
