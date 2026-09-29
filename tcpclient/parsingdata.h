/* ParsingData класс, получаем и разбираем данные */
#ifndef PARSINGDATA_H
#define PARSINGDATA_H

#include <QObject>
#include <QVariantMap>
#include <QDateTime>
#include <QTimer>

//-----------------регестрируем глобальные типы данных----------------//
//слово-состояние сервера
struct STWsrv {
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject (при обновлении полей структуры не работают сигналы и слоты, обновлять в ручную!)
    Q_PROPERTY(bool opcconn MEMBER opcconn) //для обновления данных в QML (иначе undefined)
    Q_PROPERTY(QString srvVersion MEMBER srvVersion)
    Q_PROPERTY(QVariant timestamp MEMBER timestamp)
    Q_PROPERTY(QVariant client_size MEMBER client_size)
    Q_PROPERTY(QVariant uptime MEMBER uptime)
public:
    bool opcconn = false;
    QString srvVersion;
    QVariant timestamp;
    QVariant client_size = QVariant::fromValue(0);
    QVariant uptime;
};
Q_DECLARE_METATYPE(STWsrv)

struct Event {
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject
    Q_PROPERTY(QVariant id MEMBER id)
    Q_PROPERTY(QVariant time MEMBER time)
    Q_PROPERTY(QVariant sourceName MEMBER sourceName)
    Q_PROPERTY(QVariant message MEMBER message)
public:
    QVariant id;
    QVariant time;
    QVariant sourceName;
    QVariant message;
    bool operator==(const Event &other) const { //оператор сравнения "==", чтобы moc не ругался
        return id == other.id &&
               time == other.time &&
               sourceName == other.sourceName &&
               message == other.message;
    }
    bool operator!=(const Event &other) const {
        return !(*this == other);
    }
};

//Структура аналогового сигнала
struct AI {
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject (при обновлении полей структуры не работают сигналы и слоты, обновлять в ручную!)
    Q_PROPERTY(QVariant timestamp MEMBER timestamp) //для обновления данных в QML (иначе undefined)
    Q_PROPERTY(QVariant pv MEMBER pv)
    Q_PROPERTY(QVariant lrv MEMBER lrv)
    Q_PROPERTY(QVariant urv MEMBER urv)
    Q_PROPERTY(QVariant stw MEMBER stw)
    Q_PROPERTY(QVariant tagname MEMBER tagname)
public:
    QVariant timestamp;
    QVariant pv;    //(Process Variable) - текущее значение
    QVariant lrv;   //(Lower Range Value) – нижний предел шкалы измерения (0% шкалы)
    QVariant urv;   //(Upper Range Value) – верхний предел шкалы измерения (100% шкалы)
    QVariant stw = 1;   //Word (0bit - rez, 1bit - Bad, 2bit - Warning, 3bit - Alarm) (инициализ.1, т.к. при измеении на 0 Qml не обновляется почему то!(в AI.qml stw инициализ 0))
    QVariant tagname;
    bool operator==(const AI &other) const { //оператор сравнения "==", чтобы moc не ругался
        return timestamp == other.timestamp &&
               pv == other.pv &&
               lrv == other.lrv &&
               urv == other.urv &&
               stw == other.stw &&
               tagname == other.tagname;
    }
    bool operator!=(const AI &other) const {
        return !(*this == other);
    }
};
Q_DECLARE_METATYPE(AI)

//Структура параметра TAG (ModbusTCP, и тд...)
struct TAG {
    Q_GADGET
    Q_PROPERTY(QVariant timestamp MEMBER timestamp)
    Q_PROPERTY(QVariant pv MEMBER pv)
    Q_PROPERTY(QVariant tagname MEMBER tagname)
public:
    QVariant timestamp;
    QVariant pv;
    QVariant tagname;
    bool operator==(const TAG &other) const { //оператор сравнения "==", чтобы moc не ругался
        return timestamp == other.timestamp &&
               pv == other.pv &&
               tagname == other.tagname;
    }
    bool operator!=(const TAG &other) const {
        return !(*this == other);
    }
};

//Структура точки для добавления на график
struct TagValue {
    QVariant timestamp;
    QVariant value;
};

struct Data {
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject (при обновлении полей структуры не работают сигналы и слоты, обновлять в ручную!)
    Q_PROPERTY(QList<Event> events MEMBER events) //для обновления данных в QML (иначе undefined)
    Q_PROPERTY(AI PT908 MEMBER PT908) //для обновления данных в QML (иначе undefined)
    Q_PROPERTY(AI AT901 MEMBER AT901)
    Q_PROPERTY(AI TT203 MEMBER TT203)
    Q_PROPERTY(AI TT205 MEMBER TT205)
    Q_PROPERTY(AI TT704 MEMBER TT704)
    Q_PROPERTY(AI TE601 MEMBER TE601)
    Q_PROPERTY(AI TT901 MEMBER TT901)
    Q_PROPERTY(AI TT903 MEMBER TT903)
    //GTU
    Q_PROPERTY(AI ST50 MEMBER ST50)
    Q_PROPERTY(AI FT901 MEMBER FT901)
    Q_PROPERTY(AI PT701 MEMBER PT701)
    Q_PROPERTY(AI TE701 MEMBER TE701)
    Q_PROPERTY(AI KC1 MEMBER KC1)
    Q_PROPERTY(AI KC2 MEMBER KC2)
    Q_PROPERTY(AI KC3 MEMBER KC3)
    Q_PROPERTY(AI KC4 MEMBER KC4)
    Q_PROPERTY(AI KC5 MEMBER KC5)
    Q_PROPERTY(AI TE71 MEMBER TE71)
    //Fuel
    Q_PROPERTY(AI FV401_2 MEMBER FV401_2)
    Q_PROPERTY(AI FC424 MEMBER FC424)
    Q_PROPERTY(AI PT403 MEMBER PT403)
    Q_PROPERTY(AI TT401 MEMBER TT401)
    //Reductor
    Q_PROPERTY(AI TE576 MEMBER TE576)
    Q_PROPERTY(AI TE577 MEMBER TE577)
    Q_PROPERTY(AI TE578 MEMBER TE578)
    Q_PROPERTY(AI TE579 MEMBER TE579)
    Q_PROPERTY(AI TE580 MEMBER TE580)
    Q_PROPERTY(AI TE581 MEMBER TE581)
    //GEN
    Q_PROPERTY(AI TFU MEMBER TFU)
    Q_PROPERTY(AI TFV MEMBER TFV)
    Q_PROPERTY(AI TFW MEMBER TFW)
    Q_PROPERTY(AI Tnde MEMBER Tnde)
    Q_PROPERTY(AI Tde MEMBER Tde)

    Q_PROPERTY(TAG F72 MEMBER F72)
    Q_PROPERTY(TAG WRKTM MEMBER WRKTM)
    Q_PROPERTY(TAG MODE_DESCR MEMBER MODE_DESCR)
    Q_PROPERTY(TAG STEP_DESCR MEMBER STEP_DESCR)
    Q_PROPERTY(TAG COUNTDOWN MEMBER COUNTDOWN)
public:
    QList<Event> events;
    AI PT908;   //Ратм
    AI AT901;   //Влажность
    AI TT203;   //Тсекции АВОМ
    AI TT205;   //Твых АВОМ
    AI TT704;   //Твых отсека энергетич
    AI TE601;   //Т отсека электротех
    AI TT901;   //Тперед компр
    AI TT903;   //Татм
    //GTU
    AI ST50;    //Обороты турбины
    AI FT901;   //Расход воздуха
    AI PT701;   //Pk
    AI TE701;   //Температура после компр.
    AI KC1;
    AI KC2;
    AI KC3;
    AI KC4;
    AI KC5;
    AI TE71;    //Т выхлопа (средняя)
    //Fuel
    AI FV401_2; //ДГ
    AI FC424;   //Расход ТГ
    AI PT403;   //Давление ТГ
    AI TT401;   //Температура ТГ
    //Reductor
    AI TE576;   //Т подш.планет.ряда вх.сторона т.1
    AI TE577;   //Т подш.планет.ряда вх.сторона т.2
    AI TE578;   //Т подш.планет.ряда вх.сторона т.3
    AI TE579;   //Т подш.планет.ряда вых.сторона т.1
    AI TE580;   //Т подш.планет.ряда вых.сторона т.2
    AI TE581;   //Т подш.планет.ряда вых.сторона т.3
    //GEN
    AI TFU;     //Tфазы U
    AI TFV;     //Tфазы V
    AI TFW;     //Tфазы W
    AI Tnde;    //T подш. с не приводной стороны
    AI Tde;     //T подш. с приводной стороны

    TAG F72;    //Частота вращения генератора
    TAG WRKTM;  //Наработка
    TAG MODE_DESCR;  //Текущий режим или процесс
    TAG STEP_DESCR;  //Описание действий на шаге
    TAG COUNTDOWN;  //Обратный отсчет шагов
};
Q_DECLARE_METATYPE(Data)

//не забываем добавить qRegisterMetaType<Data>("Data") в main.cpp
//-------------------------------------------------------------------//

class ParsingData : public QObject
{
    Q_OBJECT

private:
    explicit ParsingData(QObject *parent = nullptr);
    ~ParsingData();

public:
    static ParsingData *getInstance();

private:
    STWsrv m_stw;
    Data m_data;
    QTimer *m_throttleTimer = nullptr;

    void setBit(QVariant &value, const quint8 &bitPosition, const bool &state);
    TagValue fetchValue(const QString &key, const QVariantMap &map);
    void parsingAI(AI &tag, const QString &str, const QVariantMap &map);        //аналоговые параметры
    void parsingMTCP(TAG &tag, const QString &str, const QVariantMap &map);     //данные полученные с ModbusTCP
    void parsingLogic(TAG &tag, const QString &str, const QVariantMap &map);    //данные переменных из алгоритмов (расчетные)
    void currentData(const QVariantMap &map);
    void onThrottleTimer(); //тротлинг обновлений
    void historyData(const QVariantMap &map);

public:
    void engineResponse(const QVariantMap &map);
    void clientRequest(const QVariant &tagname);
    STWsrv getServerSTW(const QVariantMap &map);

signals:
    void dataUpdated(const Data &);
    void tagChanged(const QVariant &tagname, const TagValue &tagValue); //сигнал для добавления точки на график
    void sendData(const QVariantMap &);
    void addHisoryData(const QVariant &, const QList<TagValue> &);
    void status(const QString &);
};

#endif // PARSINGDATA_H
