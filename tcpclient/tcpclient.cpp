#include "tcpclient.h"

TcpClient::TcpClient(QObject *parent)
    : QObject{parent}
{
    connect(&processData, &ProcessData::status, this, &TcpClient::status);
    connect(&processData, &ProcessData::readPacketCompleted, this, &TcpClient::packetCompleted);
    connect(parsingData, &ParsingData::sendData, this, [this](const QVariantMap &map){
        socketWrite(processData.createPacket(map));
    });
    initClient();
}

TcpClient::~TcpClient()
{
    if (tcpSocket != nullptr) {
        disconnectHost();
        tcpSocket->deleteLater();
        tcpSocket = nullptr;
    };
}

void TcpClient::initClient()
{
    if (tcpSocket == nullptr) {
        tcpSocket = new QTcpSocket(this);
        QAbstractSocket::connect(tcpSocket, &QTcpSocket::connected, this, &TcpClient::slotConnected);
        QAbstractSocket::connect(tcpSocket, &QTcpSocket::disconnected, this, &TcpClient::slotDisconnected);
        QAbstractSocket::connect(tcpSocket, &QTcpSocket::errorOccurred, this, &TcpClient::slotHandleError);
        QAbstractSocket::connect(tcpSocket, &QTcpSocket::stateChanged, this, &TcpClient::slotStateChanged);
        QAbstractSocket::connect(tcpSocket, &QTcpSocket::readyRead, this, &TcpClient::socketReadyRead);
    };
    STW.objectName = AppLib::getAndroidDeviceInfo();
    STW.OSver = AppLib::getOSVersionString();
    STW.appver = AppLib::getAppVersion();
}

void TcpClient::connectHost(const QVariant &host, const QVariant &port)
{
    if (tcpSocket != nullptr && tcpSocket->state() == QAbstractSocket::ConnectedState) {
        emit status(QString("[Info] %1, Connected: %2:%3").arg(Q_FUNC_INFO, host.toString(), port.toString()));
        return;
    }

    if (tcpSocket != nullptr && tcpSocket->state() == QAbstractSocket::UnconnectedState) {
        emit status(QString("[Info] %1, Connecting... %2:%3").arg(Q_FUNC_INFO, host.toString(), port.toString()));
        tcpSocket->connectToHost(host.toString(), port.toUInt(), QIODevice::ReadWrite, QAbstractSocket::IPv4Protocol);

        if (!tcpSocket->waitForConnected(2000)) {
            emit status(QString("[Error] %1, %2").arg(Q_FUNC_INFO, tcpSocket->errorString()));
        }
    }
}

void TcpClient::disconnectHost()
{
    if (tcpSocket != nullptr && tcpSocket->state() == QAbstractSocket::ConnectedState) {
        tcpSocket->disconnectFromHost();
    }
}

void TcpClient::slotConnected()
{
    //авторизуемся на сервере
    QVariantMap map;
    map.insert("CLIENT.LOGIN", processData.getCredentials().login);
    map.insert("CLIENT.PASS", processData.getCredentials().pass);
    map.insert("CLIENT.NAME", STW.objectName);
    map.insert("CLIENT.OSVER", STW.OSver);
    map.insert("CLIENT.APPVER", STW.appver);
    socketWrite(processData.createPacket(map));

    STW.conn = true;
    emit clientUpdated(STW);
}

void TcpClient::slotDisconnected()
{
    STW.conn = false;
    emit clientUpdated(STW);
}

void TcpClient::slotHandleError(QAbstractSocket::SocketError error)
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if (socket) {
        emit status(QString("[Error] %1, %2:%3, %4").arg(Q_FUNC_INFO,
                                                         socket->peerAddress().toString(),
                                                         QString::number(socket->peerPort()),
                                                         socket->errorString()));
    }
}

void TcpClient::slotStateChanged(QAbstractSocket::SocketState state)
{
    static const QMap<QAbstractSocket::SocketState, QString> stateMap = {
        {QAbstractSocket::UnconnectedState, tr("Unconnected")},
        {QAbstractSocket::HostLookupState, tr("Host Lookup")},
        {QAbstractSocket::ConnectingState, tr("Connecting")},
        {QAbstractSocket::ConnectedState, tr("Connected")},
        {QAbstractSocket::BoundState, tr("Bound")},
        {QAbstractSocket::ListeningState, tr("Listening")},
        {QAbstractSocket::ClosingState, tr("Closing")}
    };
    emit this->status(QString("[Info] %1, Socket state changed: %2").arg(Q_FUNC_INFO, stateMap.value(state, tr("Unknown State"))));
}

void TcpClient::socketReadyRead()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if (socket->state() == QAbstractSocket::ConnectedState) {
        qint64 bytes = socket->bytesAvailable();
        STW.Rx += bytes;
        emit clientUpdated(STW);
        processData.readPacket(tcpSocket->readAll()); //обратный вызов по готовности через сигнал
    }
}

void TcpClient::packetCompleted(const QVariantMap &map)
{
    /* Переданный пакет готов (собран и расшифрован) */
    parsingData->engineResponse(map);
    emit serverUpdated(parsingData->getServerSTW(map));
    // qDebug() << Q_FUNC_INFO << map;
}

void TcpClient::socketWrite(const QByteArray &abyte)
{
    if (tcpSocket->state() == QAbstractSocket::ConnectedState) {
        STW.Tx += processData.writeSocketWidthControl(tcpSocket, abyte);
        emit clientUpdated(STW);
    }
}

void TcpClient::connectToHost(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass)
{
    processData.setCred(login.toString(), pass.toString());
    connectHost(host, port);
}

void TcpClient::disconnectToHost()
{
    disconnectHost();
}
