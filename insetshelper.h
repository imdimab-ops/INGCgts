//InsetsHelper класс для определения высоты StatusBar и NavigationBar и настройски отступов приложения

#ifndef INSETSHELPER_H
#define INSETSHELPER_H

#include <QObject>
#include <QJniObject>
#include <QApplication>
#include <QDebug>
#include <QQmlEngine>
#include <QJSEngine>
#include "applib.h"
#include "version/version.h"

class InsetsHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString getAppVersion READ getAppVersion CONSTANT)
    Q_PROPERTY(QString getOpenSSLVersionString READ getOpenSSLVersionString CONSTANT)

private:
    explicit InsetsHelper(QObject *parent = nullptr);
    ~InsetsHelper();

    jfloat getDensity(const QJniObject &activity); //получаем плотность пиксела

public:
    //создаем один экземпляр класса (паттерн Singleton)
    //доступен в 1 экземпляре как из Qml так и из C++
    static InsetsHelper *getInstance(QQmlEngine *engine = nullptr, QJSEngine *jsEngine = nullptr);

    QString getAppVersion() const { return PROJECT_VERSION_FULL; }
    QString getOpenSSLVersionString() const { return AppLib::getOpenSSLVersionString(); }
    Q_INVOKABLE int getStatusBarHeight(); //Q_INVOKABLE - макрос для доступа функции из Qml
    Q_INVOKABLE int getNavigationBarHeight();
    Q_INVOKABLE void lockPortrait();
    Q_INVOKABLE void unlockOrientation();
    Q_INVOKABLE void setImmersiveMode(const bool &enable);
    Q_INVOKABLE void vibrateAndroid(const int &milliseconds);
    void hideCameraCutoutInLandscape();

signals:
};

#endif // INSETSHELPER_H
