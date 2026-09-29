//AppEngine основной класс для работы с UI на основе Qml, инкапсулирует в себе методы и сигналы для работы с UI

#ifndef APPENGINE_H
#define APPENGINE_H

#include <QObject>
#include <QVariant>
#include <QCoreApplication>
#include <QTimer>
#include "tcpclient/tcpthread.h"
#include "lib/customplotitem.h"

class AppEngine : public QObject
{
    Q_OBJECT

private:
    TcpThread *client = TcpThread::getInstance();

    struct Details
    {
        Details() {}
        QVariant host = "5.140.165.28";
        QVariant port = "5577";
        QVariant login = "userINGCgts";
        QVariant pass = "userINGC";
    };
    Details details;

    uint m_client_size = 0; //количество клиентов на сервере

private slots:
    void slotSendData();
    void in_app(const QVariant &arg);

public:
    explicit AppEngine(QObject *parent = nullptr);
    ~AppEngine();


public slots:
    void initConnectToServer();

    //Get from UI (Frontend)
    void fgetConnectSettings();
    CustomPlotItem *fgetCustomPlot() { return CustomPlotItem::getInstance(); } //доступ к синглтону из Qml (сделал через контекст, т.к. если импортировать в Qml как синглВ сНГтон - не всегда работет)

    //Set from UI (Frontend)
    void fsetConnectToHost(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass);
    void fsetDisconnectToHost();

    void ui_write(const QVariant &arg);



signals:
    //Update UI (Frontend)
    void fconnectSettings(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass);
    void fcliUpdate(const STWcli &);    //STW слово состояние клиента
    void fsrvUpdate(const STWsrv &);    //STW слово состояние сервера
    void fdataUpdate(const Data &);

    void fsystemLog(const QVariant &);  //системный лог

};

#endif // APPENGINE_H
