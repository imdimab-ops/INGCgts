#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QObject>
#include <QtNetwork/QTcpServer>
#include <QtNetwork/QNetworkInterface>
#include <QtNetwork/QTcpSocket>
#include <QNetworkInformation>
#include "processdata.h"
#include "parsingdata.h"
#include "../applib.h"


//-----------------регестрируем глобальные типы данных----------------//
//Слово-состояние сервера
struct SSTWcli {
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject

    Q_PROPERTY(bool conn MEMBER conn)
    Q_PROPERTY(quint64 Rx MEMBER Rx)
    Q_PROPERTY(quint64 Tx MEMBER Tx)
public:
    bool conn = false;
    QString objectName = "test_name";
    QString OSver;
    QString appver;
    quint64 Rx = 0;  //количество принятых байт
    quint64 Tx = 0;  //количество переданных байт
};
typedef SSTWcli STWcli;
Q_DECLARE_METATYPE(STWcli)

//не забываем добавить qRegisterMetaType<Data>("Data") в main.cpp
//-------------------------------------------------------------------//

class TcpClient : public QObject
{
    Q_OBJECT

public:
    explicit TcpClient(QObject *parent = nullptr);
    ~TcpClient();

private:
    QTcpSocket *tcpSocket = nullptr;
    STWcli STW;
    void initClient();

    ProcessData processData;
    ParsingData *parsingData = ParsingData::getInstance();

private slots:
    void connectHost(const QVariant &host, const QVariant &port);
    void disconnectHost();
    void slotConnected();
    void slotDisconnected();
    void slotHandleError(QTcpSocket::SocketError error);
    void slotStateChanged(QAbstractSocket::SocketState state);
    void socketReadyRead();
    void packetCompleted(const QVariantMap &map);
    void socketWrite(const QByteArray &abyte);

public slots:
    void connectToHost(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass);
    void disconnectToHost();

signals:
    void serverUpdated(const STWsrv &);
    void clientUpdated(const STWcli &);
    void status(const QString &);

};

#endif // TCPCLIENT_H
