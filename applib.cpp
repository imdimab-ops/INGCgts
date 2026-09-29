#include "applib.h"

AppLib::AppLib(QObject *parent)
    : QObject{parent}
{

}

AppLib::~AppLib()
{

}

QString AppLib::getOSVersionString()
{
    auto OS = QOperatingSystemVersion::current();
    return QString("OS: %1 %2.%3.%4").arg(OS.name()).arg(OS.majorVersion()).arg(OS.minorVersion()).arg(OS.microVersion());
}

QString AppLib::getOpenSSLVersionString()
{
    return OPENSSL_VERSION_TEXT;
}

QString AppLib::getAndroidDeviceInfo()
{
    QJniObject deviceName = QJniObject::getStaticObjectField(
        "android/os/Build",
        "DEVICE",
        "Ljava/lang/String;"
        );

    QJniObject model = QJniObject::getStaticObjectField(
        "android/os/Build",
        "MODEL",
        "Ljava/lang/String;"
        );

    QJniObject manufacturer = QJniObject::getStaticObjectField(
        "android/os/Build",
        "MANUFACTURER",
        "Ljava/lang/String;"
        );

    QJniObject release = QJniObject::getStaticObjectField(
        "android/os/Build$VERSION",
        "RELEASE",
        "Ljava/lang/String;"
        );

    jint sdkInt = QJniObject::getStaticField<jint>(
        "android/os/Build$VERSION",
        "SDK_INT"
        );

    return QString("Device:%1 %2 %3 SDK:%4")
        .arg(deviceName.toString(),
             model.toString(),
             manufacturer.toString(),
             QString::number(sdkInt));
}

void AppLib::saveSettings(const QVariantMap &map)
{
    if (map.isEmpty()) return;
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QSettings settings(configPath + "/config.ini", QSettings::IniFormat);

    settings.setValue("app", "INGC");
    settings.setValue("dt", QDateTime::currentDateTime());
    settings.setValue("connect/host", map.value("host"));
    settings.setValue("connect/port", map.value("port"));
    settings.setValue("connect/login", map.value("login"));
    settings.setValue("connect/pass", map.value("pass"));
    settings.sync(); // Принудительная синхронизация
}

QVariantMap AppLib::loadSettings()
{
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QSettings settings(configPath + "/config.ini", QSettings::IniFormat);

    QVariantMap map;
    map["app"] = settings.value("app", "test_app");
    map["host"] = settings.value("connect/host");
    map["port"] = settings.value("connect/port");
    map["login"] = settings.value("connect/login");
    map["pass"] = settings.value("connect/pass");
    return map;
}
