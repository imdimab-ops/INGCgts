#include "tcpthread.h"

TcpThread::TcpThread(QObject *parent)
    : QThread{parent}
{
    createThread();
}

TcpThread::~TcpThread()
{
    if(thread.isRunning()) {
        thread.quit();
        thread.wait();
    }
    delete tcpClient;
    tcpClient = nullptr;
}

TcpThread *TcpThread::getInstance()
{
    static TcpThread instance;
    return &instance;
}


bool TcpThread::createThread()
{
    tcpClient = new TcpClient;
    tcpClient->moveToThread(&thread);
    connect(&thread, &QThread::finished, tcpClient, &QObject::deleteLater);
    connect(this, &TcpThread::connectToHost, tcpClient, &TcpClient::connectToHost);
    connect(this, &TcpThread::disconnectToHost, tcpClient, &TcpClient::disconnectToHost);

    connect(tcpClient, &TcpClient::status, this, &TcpThread::status);
    connect(tcpClient, &TcpClient::clientUpdated, this, &TcpThread::clientUpdated);
    connect(tcpClient, &TcpClient::serverUpdated, this, &TcpThread::serverUpdated);

    ParsingData *parsingData = ParsingData::getInstance();
    parsingData->moveToThread(&thread);
    connect(&thread, &QThread::finished, parsingData, &QObject::deleteLater);
    connect(this, &TcpThread::clientRequest, parsingData, &ParsingData::clientRequest);
    connect(parsingData, &ParsingData::dataUpdated, this, &TcpThread::dataUpdated);
    connect(parsingData, &ParsingData::tagChanged, this, &TcpThread::tagChanged);
    connect(parsingData, &ParsingData::addHisoryData, this, &TcpThread::addHisoryData);
    connect(parsingData, &ParsingData::status, this, &TcpThread::status);
    thread.start();

    //кол-во логических процессоров (отображаем с задержкой, чтобы Ui с логгером успел создаться)
    QTimer::singleShot(50, this, [this]() {
        if (this->thread.isRunning()) emit status(QString("[Info] %1, idealThreadCount: %2").arg(Q_FUNC_INFO, QString::number(this->thread.idealThreadCount())));
    });

    return true;
}
