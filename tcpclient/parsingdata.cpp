#include "parsingdata.h"

ParsingData::ParsingData(QObject *parent)
    : QObject{parent}
{
    /* троттлинг обновлений (хотя данные приходят реже, сделал так, как надо :) */
    m_throttleTimer = new QTimer(this);
    m_throttleTimer->setInterval(200); //200 мс = 5 раз в секунду
    connect(m_throttleTimer, &QTimer::timeout, this, &ParsingData::onThrottleTimer);
}

ParsingData::~ParsingData()
{

}

ParsingData *ParsingData::getInstance()
{
    static ParsingData instance;
    return &instance;
}

void ParsingData::setBit(QVariant &value, const quint8 &bitPosition, const bool &state)
{
    /* устанавливаем битовую маску для статуса канала */
    int intValue = value.toInt();
    if (state) {
        intValue = intValue | (1 << bitPosition); // | - или, & - и
    } else {
        intValue = intValue & ~(1 << bitPosition); //~ инвертируем маску
    }
    value = QVariant::fromValue(intValue);
}

TagValue ParsingData::fetchValue(const QString &key, const QVariantMap &map)
{
    if (key.isEmpty() || map.isEmpty()) return TagValue{};
    if (auto it = map.constFind(key); it != map.constEnd()) { //C++17 init-statement, it живет только внутри if
        const QVariantMap tag = it.value().toMap();
        return TagValue{tag.value(QStringLiteral("TIMESTAMP")), tag.value(QStringLiteral("VALUE"))}; //QStringLiteral - компилируется в статический массив, без аллокации
    }
    return TagValue{};
}

void ParsingData::parsingAI(AI &tag, const QString &str, const QVariantMap &map)
{
    /* Парсим теги "TAG.AI.%1.XXX" - тэг со стороны сервера, пишется в сокет только при изменении!!!
     * если изменения параметра нет, то в протоле его ключ отсутствует
     * тег "TAG.AI.%1.XXX" состоит из контейнера QVariantMap, который содержит в себе данные по следующим ключам:
     * - "VALUE" - значение
     * - "STATUS" - статус данных
     * - "TIMESTAMP" - метка времени данного значения */
    const QString prefix = QStringLiteral("TAG.AI.") % str; //% - QStringBuilder, выделение строки происходит быстрее чем QString("TAG.MTCP.%1").arg(str)
    if (TagValue v = fetchValue(prefix % QStringLiteral(".PV"), map); v.value.isValid() && v.timestamp.isValid()) {
        tag.pv = v.value;
        tag.timestamp = v.timestamp;
        tag.tagname = QString(QStringLiteral("AI.") % str % QStringLiteral(".PV")); //пишем имя тега для запроса исторических данных
        emit tagChanged(tag.tagname, TagValue{tag.timestamp, tag.pv});
    }
    if (TagValue v = fetchValue(prefix % QStringLiteral(".CONFIG.YMIN"), map); v.value.isValid()) tag.lrv = v.value;
    if (TagValue v = fetchValue(prefix % QStringLiteral(".CONFIG.YMAX"), map); v.value.isValid()) tag.urv = v.value;
    if (TagValue v = fetchValue(prefix % QStringLiteral(".Fault"), map); v.value.isValid()) setBit(tag.stw, 1, v.value.toBool());
    if (TagValue v = fetchValue(prefix % QStringLiteral(".Warn"), map); v.value.isValid()) setBit(tag.stw, 2, v.value.toBool());
    if (TagValue v = fetchValue(prefix % QStringLiteral(".Alarm"), map); v.value.isValid()) setBit(tag.stw, 3, v.value.toBool());
}

void ParsingData::parsingMTCP(TAG &tag, const QString &str, const QVariantMap &map)
{
    /* Парсим теги "TAG.MTCP.%1.XXX" - тэг со стороны сервера, пишется в сокет только при изменении!!!
     * если изменения параметра нет, то в протоле его ключ отсутствует
     * тег "TAG.MTCP.%1.XXX" состоит из контейнера QVariantMap, который содержив в себе данные по следующим ключам:
     * - "VALUE" - значение
     * - "STATUS" - статус данных
     * - "TIMESTAMP" - метка времени данного значения */
    const QString prefix = QStringLiteral("TAG.MTCP.") % str; //% - QStringBuilder, выделение строки происходит быстрее чем QString("TAG.MTCP.%1").arg(str)
    if (TagValue v = fetchValue(prefix, map); v.value.isValid() && v.timestamp.isValid()) {
        tag.pv = v.value;
        tag.timestamp = v.timestamp;
        tag.tagname = QString(QStringLiteral("MTCP.") % str); //пишем имя тега для запроса исторических данных
        emit tagChanged(tag.tagname, TagValue{tag.timestamp, tag.pv});
    }
}

void ParsingData::parsingLogic(TAG &tag, const QString &str, const QVariantMap &map)
{
    /* Парсим теги "TAG.LOGIC.%1.XXX" - тэг со стороны сервера, пишется в сокет только при изменении!!!
     * если изменения параметра нет, то в протоле его ключ отсутствует
     * тег "TAG.LOGIC.%1.XXX" состоит из контейнера QVariantMap, который содержив в себе данные по следующим ключам:
     * - "VALUE" - значение
     * - "STATUS" - статус данных
     * - "TIMESTAMP" - метка времени данного значения */
    const QString prefix = QStringLiteral("TAG.LOGIC.") % str; //% - QStringBuilder, выделение строки происходит быстрее чем QString("TAG.MTCP.%1").arg(str)
    if (TagValue v = fetchValue(prefix, map); v.value.isValid() && v.timestamp.isValid()) {
        tag.pv = v.value;
        tag.timestamp = v.timestamp;
        tag.tagname = QString(QStringLiteral("LOGIC.") % str); //пишем имя тега для запроса исторических данных
        emit tagChanged(tag.tagname, TagValue{tag.timestamp, tag.pv});
    }
}

void ParsingData::currentData(const QVariantMap &map)
{
    if (map.isEmpty()) return;

    //Events
    if (auto it = map.constFind("EVENTS"); it != map.constEnd() && it->isValid()) { //C++17 init-statement, it живет только внутри if
        m_data.events.clear();
        const QList<QVariant> variantList  = it.value().toList();
        m_data.events.reserve(variantList.size());
        for (const auto &event : variantList) {
            QVariantMap vm = event.toMap();
            Event &e = m_data.events.emplaceBack(Event()); //C++17 конструирование на месте
            e.id  = vm.value(QStringLiteral("id"));
            e.time = vm.value(QStringLiteral("time"));
            e.sourceName = vm.value(QStringLiteral("sourceName"));
            e.message = vm.value(QStringLiteral("message"));
        }
    }

    //AI
    parsingAI(m_data.PT908, "PT908", map);
    parsingAI(m_data.AT901, "AT901", map);
    parsingAI(m_data.TT203, "TT203", map);
    parsingAI(m_data.TT205, "TT205", map);
    parsingAI(m_data.TT704, "TT704", map);
    parsingAI(m_data.TE601, "TE601", map);
    parsingAI(m_data.TT901, "TT901", map);
    parsingAI(m_data.TT903, "TT903", map);
    //AI_GTU
    parsingAI(m_data.ST50, "ST50", map);
    parsingAI(m_data.FT901, "FT901", map);
    parsingAI(m_data.PT701, "PT701", map);
    parsingAI(m_data.TE701, "TE701", map);
    parsingAI(m_data.KC1, "TE521", map);
    parsingAI(m_data.KC2, "TE522", map);
    parsingAI(m_data.KC3, "TE523", map);
    parsingAI(m_data.KC4, "TE524", map);
    parsingAI(m_data.KC5, "TE525", map);
    parsingAI(m_data.TE71, "TE71", map);
    //AI_Fuel
    parsingAI(m_data.FV401_2, "FV401_2", map);
    parsingAI(m_data.FC424, "FC424", map);
    parsingAI(m_data.PT403, "PT403", map);
    parsingAI(m_data.TT401, "TT401", map);
    //AI_RED
    parsingAI(m_data.TE576, "TE576", map);
    parsingAI(m_data.TE577, "TE577", map);
    parsingAI(m_data.TE578, "TE578", map);
    parsingAI(m_data.TE579, "TE579", map);
    parsingAI(m_data.TE580, "TE580", map);
    parsingAI(m_data.TE581, "TE581", map);
    //AI_GEN
    parsingAI(m_data.TFU, "TE590", map);
    parsingAI(m_data.TFV, "TE592", map);
    parsingAI(m_data.TFW, "TE594", map);
    parsingAI(m_data.Tnde, "TE596", map);
    parsingAI(m_data.Tde, "TE597", map);
    //MTCP
    parsingMTCP(m_data.F72, "TIK.F72", map); //частота вращения генератора
    //ALG
    parsingLogic(m_data.WRKTM, "WRKTM.OH", map); //наработка, час
    parsingLogic(m_data.MODE_DESCR, "MODE_DESCRIPTION", map);
    parsingLogic(m_data.STEP_DESCR, "STEP_DESCRIPTION", map);
    parsingLogic(m_data.COUNTDOWN, "COUNTDOWN.RT", map);

    if (m_throttleTimer && !m_throttleTimer->isActive()) {
        m_throttleTimer->start();
    }
    // qDebug() << Q_FUNC_INFO << m_data.TFU.pv << m_data.TFU.urv << m_data.TFU.stw;
}

void ParsingData::onThrottleTimer()
{
    emit dataUpdated(m_data);
}

void ParsingData::historyData(const QVariantMap &map)
{
    QVariant tag = map.value("TAG.HISTORY");
    if (tag.isValid()) {
        QVariantList historyList = map.value("DATA").toList();
        QList<TagValue> points;
        for(const auto &variant : std::as_const(historyList)) {
            auto point = variant.toMap();
            TagValue tv = TagValue{point.value(QStringLiteral("TIMESTAMP")), point.value(QStringLiteral("VALUE"))}; //QStringLiteral - компилируется в статический массив, без аллокации
            points.append(std::move(tv));
        }
        emit addHisoryData(tag, points);
        emit status(QString("[Info] %1, TAG.HISTORY: %2, size: %3").arg(Q_FUNC_INFO, tag.toString(), QString::number(historyList.size())));
    }
    // qDebug() << Q_FUNC_INFO << map;
}

void ParsingData::engineResponse(const QVariantMap &map)
{
    /* обрабатываем ответы сервера */
    if (map.isEmpty()) return;
    QString response = map.value("SERVER.RESPONSE").toString();

    if (response == QString("ALL_DATA") || response == QString("CURRENT_DATA")) {
        currentData(map);
    }
    if (response == QString("HISTORY_DATA")) {
        historyData(map);
    }
}

void ParsingData::clientRequest(const QVariant &tagname)
{
    if (tagname.isNull()) return;
    emit sendData(QVariantMap{{"CLIENT.REQUEST", "HISTORY_DATA"}, {"TAG.HISTORY", tagname}});
}

STWsrv ParsingData::getServerSTW(const QVariantMap &map)
{
    if (map.isEmpty()) return m_stw;
    if (auto it = map.constFind(QStringLiteral("SERVER.OPCCONNECT")); it != map.constEnd()) m_stw.opcconn = it->toBool();
    if (auto it = map.constFind(QStringLiteral("SERVER.VERSION")); it != map.constEnd()) m_stw.srvVersion = it->toString();
    if (auto it = map.constFind(QStringLiteral("SERVER.TIMESTAMP")); it != map.constEnd()) m_stw.timestamp = it.value();
    if (auto it = map.constFind(QStringLiteral("SERVER.CLIENTSIZE")); it != map.constEnd()) m_stw.client_size = it.value();
    if (auto it = map.constFind(QStringLiteral("SERVER.UPTIME")); it != map.constEnd()) m_stw.uptime = it.value();
    return m_stw;
}
