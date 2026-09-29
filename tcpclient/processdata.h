#ifndef PROCESSDATA_H
#define PROCESSDATA_H

#include <QObject>
#include <QtNetwork/QTcpSocket>
#include <QDateTime>
#include <QTimer>
#include <QByteArray>
#include <QCryptographicHash>
#include <QCoreApplication>
#include <QIODevice>
#include <openssl/aes.h>
#include <openssl/evp.h>

//-----------------регестрируем глобальные типы данных----------------//
struct Credentials  {
    QString login = "userINGCgts";   //логин и пароль для авторизации на сервере
    QString pass = "userINGC";
    QByteArray key; //ключ шифрования
    QByteArray iv;  //вектор шифрования
};
//-------------------------------------------------------------------//

class ProcessData : public QObject
{
    Q_OBJECT
public:
    explicit ProcessData(QObject *parent = nullptr);
    ~ProcessData();

private:
    Credentials m_cred;

    struct Buffer { //буфер для сбора TCP пакетов (мах размер передаваемого пакета 1448байт)
        QByteArray abytes = 0;
        quint32 bodySize = 0;
        bool headerRead = false;
        bool bodyCompressed = false;
    };
    Buffer m_buffer;

    static constexpr qint64 MAX_COMPRESS_SIZE = 1073741824; // 2^30 = 1 GiB (~1GB)
    static constexpr qsizetype HEADER_SIZE   = sizeof(quint32) + sizeof(quint8) + sizeof(quint8) + sizeof(quint16); //8байт
    static constexpr quint32 MAX_BODY_SIZE = 64u * 1024u * 1024u;   //64 МБ (максимальный размер буфера данных)
    static constexpr quint8 FLAG_COMPRESSED = 0x01;

    void generateCryptKey(const QString &login, const QString &pass);
    QByteArray encrypt(const QByteArray &crypba, const QByteArray &key, const QByteArray &iv);
    QByteArray decrypt(const QByteArray &encrba, const QByteArray &key, const QByteArray &iv);
    QByteArray compressData(const QByteArray &ba, bool &compressed);
    QByteArray uncompressData(const QByteArray &ba);

public:
    void setCred(const QString &login, const QString &pass);

public slots:
    QByteArray createPacket(const QVariantMap &map);
    void readPacket(const QByteArray &packet);
    qint64 writeSocketWidthControl(QTcpSocket *socket, const QByteArray &data); //записть в сокет с контролем буфера TCP
    Credentials getCredentials();

signals:
    void status(const QString &);
    void readPacketCompleted(const QVariantMap &);

};

#endif // PROCESSDATA_H
