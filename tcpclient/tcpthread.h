#ifndef TCPTHREAD_H
#define TCPTHREAD_H

#include <QThread>
#include "tcpclient.h"
#include "parsingdata.h"

class TcpThread : public QThread
{
    Q_OBJECT

private:
    explicit TcpThread(QObject *parent = nullptr);
    ~TcpThread();

    TcpClient *tcpClient = nullptr;
    QThread thread;
    bool createThread();

public:
    static TcpThread *getInstance();

signals:
    /* In */
    void connectToHost(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass);
    void disconnectToHost();
    void setUser(const QVariant &setLogin, const QVariant &setPass);

    /* ParsingData */
    void clientRequest(const QVariant &);

    /* Out */
    void serverUpdated(const STWsrv &);
    void clientUpdated(const STWcli &);
    void dataUpdated(const Data &);
    void tagChanged(const QVariant &, const TagValue &); //сигнал для добавления точки на график
    void addHisoryData(const QVariant &, const QList<TagValue> &);
    void status(const QString &);

};

#endif // TCPTHREAD_H
