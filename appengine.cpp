#include "appengine.h"

AppEngine::AppEngine(QObject *parent)
    : QObject{parent}
{
    connect(client, &TcpThread::clientUpdated, this, &AppEngine::fcliUpdate);  //словосостояние клиента

    connect(client, &TcpThread::serverUpdated, this, [this](const STWsrv &STW){ //захват по ссылке для возможности изменения
        emit fsrvUpdate(STW);
        if (m_client_size != STW.client_size.toUInt()) {
            m_client_size = STW.client_size.toUInt();
            emit fsystemLog(QVariant::fromValue(QString("[Info] %1 client_size: %2").arg(Q_FUNC_INFO, QString::number(m_client_size))));
        }
    });
    connect(client, &TcpThread::dataUpdated, this, &AppEngine::fdataUpdate);
    connect(client, &TcpThread::tagChanged, this, [this](const QVariant &tagname, const TagValue &tagValue){
        auto plot = CustomPlotItem::getInstance();
        if (plot) plot->addPointToGraph(tagname, tagValue);

    });
    connect(client, &TcpThread::addHisoryData, this, [this](const QVariant &tagname, const QList<TagValue> &tagValues){
        auto plot = CustomPlotItem::getInstance();
        if (plot) plot->addPointsToGraph(tagname, tagValues);
    });
    connect(client, &TcpThread::status, this, &AppEngine::fsystemLog);

    QTimer::singleShot(25, this, [this]() {
        // initConnectToServer(); //инициализируем подключеение (app загружается быстро, когда обмен реализован в отдельном потоке)
    });
}

AppEngine::~AppEngine()
{
    qDebug() << "AppEngine close";
}

void AppEngine::initConnectToServer()
{
    QVariantMap map = AppLib::loadSettings();
    if (map.contains("host") && map.value("host").isValid()) details.host = map.value("host");
    if (map.contains("port") && map.value("port").isValid()) details.port = map.value("port");
    if (map.contains("login") && map.value("login").isValid()) details.login = map.value("login");
    if (map.contains("pass") && map.value("pass").isValid()) details.pass = map.value("pass");
    emit client->connectToHost(details.host, details.port, details.login, details.pass);
}

void AppEngine::fgetConnectSettings()
{
    emit fconnectSettings(details.host, details.port, details.login, details.pass);
}

void AppEngine::slotSendData()
{
    // server->sendData();
}

void AppEngine::fsetConnectToHost(const QVariant &host, const QVariant &port, const QVariant &login, const QVariant &pass)
{
    details.host = host;
    details.port = port;
    details.login = login;
    details.pass = pass;
    emit client->connectToHost(details.host, details.port, details.login, details.pass);
    AppLib::saveSettings(QVariantMap{{"host", details.host},
                                     {"port", details.port},
                                     {"login", details.login},
                                     {"pass", details.pass}});
}

void AppEngine::fsetDisconnectToHost()
{
    emit client->disconnectToHost();
}

void AppEngine::in_app(const QVariant &arg)
{
    qDebug() << Q_FUNC_INFO << arg.toString();
}

void AppEngine::ui_write(const QVariant &arg)
{
    qDebug() << Q_FUNC_INFO << arg.toString();
}
