#ifndef CUSTOMPLOTITEM_H
#define CUSTOMPLOTITEM_H

#include <QQuickPaintedItem>
#include <QTouchEvent>
#include <QQuickWindow>
#include <QDebug>
#include <QQmlEngine>
#include "qcustomplot.h"
#include "millisecondticker.h"
#include "../tcpclient/tcpthread.h"

//-----------------регестрируем глобальные типы данных----------------//
//Параметры графика
struct GraphParam
{
    Q_GADGET  //Макрос для QML-доступа без наследования от QObject
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(QColor color MEMBER color)
    Q_PROPERTY(bool checked MEMBER checked)
public:
    QString name;   //Имя графика
    QColor color;
    bool checked;   //Статуc отмечен или нет
};
typedef GraphParam GraphParam;
Q_DECLARE_METATYPE(GraphParam)

//не забываем добавить qRegisterMetaType<GraphParam>("GraphParam") в main.cpp
//-------------------------------------------------------------------//

class QCPAbstractPlottable;

class CustomPlotItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_DISABLE_COPY(CustomPlotItem)

public:
    CustomPlotItem(QQuickItem *parent = nullptr);
    virtual ~CustomPlotItem();

private:
    void initCustomPlot();
    void updateCustomPlotSize();
    bool addGraph(const QString &name, const QString &tagname);
    void removeGraph(QCPGraph *graph);
    void removeAxis(QCPAxis *axis);
    QCPGraph *getGraphByTag(const QString &tagname);
    void updateAxisMargins();
    bool createdLegend();
    void updateCursorPosition(const double &x);
    void handleDoubleClick();
    void getLastData(QCPGraph *graph);
    void updateGraphDataCount();
    void extensionGraphLines(const double &time); //"подтяжка графика" добавление предыдущих точек к графикам, чтобы не отставали
    void trimToLimit(QCPGraph *graph); //подрезка до лимита точек

    QCustomPlot *m_customPlot = nullptr;
    inline static CustomPlotItem *instance = nullptr; //Статическая перменная (иниц. в стат. памяти 1раз)
    bool m_isZoomed = false;      //для отслеживания зума
    bool m_aScroll = true;        //автоскролл
    bool m_selectedGraph = false; //выбран один из графиков для перемещения, зума
    static constexpr double TIME_WINDOW = 600*1000; //ms (10минут)

    static constexpr quint8 AXIS_SPACING = 17; //смещение оси Y

    //"подтяжка графика"
    bool m_throttlingGraphLines = false; //тротлинг для добавления предыдущих точек к графикам, чтобы не отставали
    double m_maxTimeGraph = 0; //время графика который левее продвинулся относительно остальных

    //Для легенды
    QHash<QCPGraph*, QCPLayoutInset*> m_hashLegendText; //Хэш для хранения графика с кастомными строками легенды (строки хранятся в контейнере)

    //Хэш для хранения коннектов связных осей (connect для синхронизации движения осей), для дальнейшего удаления
    QHash<QCPAxis*, QMetaObject::Connection> m_hashAxisConnections;

    //Для визирной линии
    QCPItemStraightLine *m_cursorLine = nullptr;
    QCPItemText *m_cursorLabel = nullptr;
    bool m_cursorVisible = false;
    QTimer m_clickTimer;
    int m_clickCount = 0;

    static constexpr quint16 MAX_LENGTH = 10000; //max длина вектора графика
    static constexpr int GRAPH_SIZE = 8;  //количество возможных графиков
    int settingGraphCount = 0;
    struct SettingGraph
    {
        SettingGraph(const QColor &c, const QCPScatterStyle &s) : color(c), scatter(s) {}
        QColor color;
        QCPScatterStyle scatter;
    };
    QList <SettingGraph> m_storeSettingGraph = {
                                                {Qt::black, QCPScatterStyle::ssDot},
                                                {Qt::green, QCPScatterStyle::ssCross},
                                                {Qt::red, QCPScatterStyle::ssPlus},
                                                {Qt::gray, QCPScatterStyle::ssCircle},
                                                {Qt::blue, QCPScatterStyle::ssDisc},
                                                {Qt::cyan, QCPScatterStyle::ssSquare},
                                                {Qt::magenta, QCPScatterStyle::ssDiamond},
                                                {Qt::darkGreen, QCPScatterStyle::ssStar},
                                                };

private slots:

protected: //доступ в наследниках
    //Обработка касаний (Android)
    void touchEvent(QTouchEvent *event) override;
    void paint(QPainter *painter) override;
    bool isModalWindowOpen(); //Если надо ослеживать модальные окна (В элементе Qml необохоимо установить св-во modal:true)

    //Обработчик таймера
    void timerEvent(QTimerEvent *event) override;

    //Get from UI (Frontend)
    Q_INVOKABLE QVariant fgetGraphList();

    //Set from UI (Frontend)
    Q_INVOKABLE void fsetInitPlot();
    Q_INVOKABLE void fsetAutoScroll(const bool &arg);
    Q_INVOKABLE void fsetCursorLine(const bool &arg);
    Q_INVOKABLE void fsetAddGraph(const QVariant &addTag, const QVariant &name, const QVariant &tagname);
    Q_INVOKABLE void fsetSelectedGraph(const QVariant &name, const bool &checked);
    Q_INVOKABLE void fsetDeletedGraph(const QVariant &name);

public:
    static CustomPlotItem *getInstance(); //метод для доступа к синглтону из C++
    void addPointsToGraph(const QVariant &tagname, const QList<TagValue> &tagValues);
    void addPointToGraph(const QVariant &tagname, const TagValue &tagValue);

signals:
    //Local
    void addedGraph(QCPGraph *graph);

    //Update UI (Frontend)
    void fautoScroll(const bool &arg);
    void fcursorLine(const bool &arg);
    void fdataCount(const quint32 &arg); //общее количество точек на графике
    void fdeletedGraph(const QString &name);

};

#endif // CUSTOMPLOTITEM_H
