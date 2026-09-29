//#include <QGuiApplication>    //только QML
#include <QApplication> //для QML и Qt Widgets
#include <QQmlApplicationEngine>
#include <QQmlContext>  //для setContextProperty

#include "appengine.h"
#include "insetshelper.h"
#include "lib/customplotitem.h"

int main(int argc, char *argv[])
{
    //регестрируем глобальные типы данных
    qRegisterMetaType<STWcli>("STWcli");
    qRegisterMetaType<AI>("AI");
    // qRegisterMetaType<EventData>("EventData");

    //QGuiApplication app(argc, argv);
    QApplication app(argc, argv);   //отображаем элементы QWidget

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    //Синглтон, отдельный бэкэнд только для QML
    qmlRegisterSingletonType<InsetsHelper>("InsetsHelper", 1, 0, "InsetsHelper", InsetsHelper::getInstance);
    qmlRegisterType<CustomPlotItem>("CustomPlot", 1, 0, "CPlot");   //при вызове в Qml создаем единственный экземпляр, который становится синглтоном
    qmlRegisterType<AppEngine>("AppEngine", 1, 0, "AppEng"); //регестрируем только для работы всплывающих подсказок в Qml, так работает через контекст setContextProperty

    //Создаём менеджер как дочерний объект движка
    auto appEngine = new AppEngine(&engine);
    engine.rootContext()->setContextProperty("appEng", appEngine);
    //Защита от двойного удаления
    QObject::connect(&engine, &QQmlEngine::destroyed, &engine, [appEngine]() {
        if(appEngine) {
            appEngine->deleteLater();
        }
    });

    engine.loadFromModule("INGCgts", "SplashScreen"); //загружаем SplashScreen.qml из модуля URI INGCgts

    /* инициализируем подключение вновь, когда приложение активно, т.к. при работе приложения в фоне Android рвет соединение */
    QObject::connect(&app, &QApplication::applicationStateChanged, &app, [appEngine](Qt::ApplicationState state){
        switch (state) {
        case Qt::ApplicationActive:
            appEngine->initConnectToServer();
            emit appEngine->fsystemLog(QString("[Info] %1 dbogomolov").arg(Q_FUNC_INFO));
            qDebug() << Q_FUNC_INFO << "App became active";
            break;
        case Qt::ApplicationSuspended:
            qDebug() << Q_FUNC_INFO << "App went to background";
            break;
        case Qt::ApplicationHidden:
            qDebug() << Q_FUNC_INFO << "App hidden";
            break;
        case Qt::ApplicationInactive:
            qDebug() << Q_FUNC_INFO << "App inactive";
            break;
        default:
            break;
        }
    });

    return app.exec();
}
