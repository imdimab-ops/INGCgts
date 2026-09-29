#include "customplotitem.h"

CustomPlotItem::CustomPlotItem(QQuickItem* parent) : QQuickPaintedItem(parent)
{
    /* инициализация сигнлтона для построения графиков!!!:
     * 1.при запуске программы инциализируется статическая переменная 1раз CustomPlotItem *instatnce = nullptr;
     * 2.при созданни первого экземляра в Qml, статической переменной instatnce в конструкторе присваивается
     *   указатель на первый созданный объект if (!instance) instance = this; и объект становится синглтоном;
     * 3.последующие вызовы через getInstance() - получаем доступ с синглтону (обязательно проверка nullptr) */
    if (!instance) instance = this; //первый созданный объект в Qml остается синглтоном

    this->setFlag(QQuickItem::ItemHasContents, true);
    this->setAcceptedMouseButtons(Qt::AllButtons);
    this->setAcceptTouchEvents(true); // Включаем обработку касаний
    this->setFlag(ItemAcceptsInputMethod, true);

    //Настройки рендеринга
    // setRenderTarget(QQuickPaintedItem::FramebufferObject);   //рендеринг через графический буфер в GPU (Отрисовка зависает при открытии модальных окон)
    // setTextureSize(QSize(width(), height())); // Фиксированный размер текстуры
    // setPerformanceHint(QQuickPaintedItem::FastFBOResizing, true);
    setRenderTarget(QQuickPaintedItem::Image);  //рендеринг в CPU (Отрисовка работает без замечаний)

    m_clickTimer.setInterval(300);
    connect(&m_clickTimer, &QTimer::timeout, this, [this](){ m_clickCount = 0; });

    //При изменении окна обновляем размеры
    connect(this, &QQuickPaintedItem::widthChanged, this, &CustomPlotItem::updateCustomPlotSize);
    connect(this, &QQuickPaintedItem::heightChanged, this, &CustomPlotItem::updateCustomPlotSize);
}

CustomPlotItem::~CustomPlotItem()
{
    this->setEnabled(false); //Отключаем все входящие события

    if (m_customPlot) {
        m_customPlot->clearGraphs();
        delete m_customPlot;
        m_customPlot = nullptr;
        if (m_cursorLine) {
        }
        delete m_cursorLine;
        m_cursorLine = nullptr;
    }
    if (m_cursorLabel) {
        delete m_cursorLabel;
        m_cursorLabel = nullptr;
    }
    if (instance == this) {
        instance = nullptr;
    }
}

void CustomPlotItem::initCustomPlot()
{
    //Инициализируем из Qml
    if (m_customPlot) return;
    m_customPlot = new QCustomPlot();
    connect(m_customPlot, &QCustomPlot::afterReplot, this, [this](){ update(); }); //л-функция (обновление после replot)
    updateCustomPlotSize();
    //оптимизация производительности
    // m_customPlot->setOpenGl(true);
    // m_customPlot->setNotAntialiasedElements(QCP::aeAll);  //отключаем сглаживание для всех элементов
    m_customPlot->setNoAntialiasingOnDrag(true);          //отключаем сглаживания для элементов графика

    m_customPlot->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iMultiSelect);

    //Настраиваем оси (они будут использованы для первого графика)
    m_customPlot->axisRect()->setAutoMargins(QCP::msNone);        //Отключить автоматические отступы
    m_customPlot->axisRect()->setMargins(QMargins(15, 0, 0, 15)); //Установить минимальные отступы
    m_customPlot->plotLayout()->setMargins(QMargins(0, 0, 0, 0)); //Установить отступы макета

    //Настройки шрифта
    QFont font("DejaVu Sans", 10, QFont::Normal);
    font.setStyleStrategy(QFont::NoAntialias); //для четкого отображения
    // font.setStyleStrategy(QFont::PreferAntialias);      //Сглаживание ВКЛ
    font.setHintingPreference(QFont::PreferVerticalHinting); //Только вертикальный хинтинг
    font.setWeight(QFont::Normal);
    font.setStyleHint(QFont::SansSerif);                // Без засечек

    m_customPlot->xAxis->setRange(0, 12);
    m_customPlot->xAxis->setTickLabelPadding(0);  //Отступ до значений оси
    m_customPlot->xAxis->setTickLabelFont(font);
    //Устанавливаем формат оси X как время
    // QSharedPointer<QCPAxisTickerDateTime> dateTicker(new QCPAxisTickerDateTime);
    // dateTicker->setDateTimeFormat("hh:mm:ss");
    // m_customPlot->xAxis->setTicker(dateTicker);
    QSharedPointer<MilliSecondTicker> msecTicker(new MilliSecondTicker()); //кастомный формат в msec
    m_customPlot->xAxis->setTicker(msecTicker);

    m_customPlot->yAxis->setRange(0, 5);
    m_customPlot->yAxis->setLabelFont(font);
    m_customPlot->yAxis->setTickLabelPadding(-2);
    m_customPlot->yAxis->setTickLabelRotation(-90);
    m_customPlot->yAxis->setTickLabelFont(font);
    m_customPlot->yAxis->setLabelPadding(-12);

    if (!m_customPlot->size().isNull()) m_customPlot->replot();    //Перед отрисовкой проверям размер области, должна быть не 0, иначе crash

    m_customPlot->addLayer("cursorLayer", 0, QCustomPlot::LayerInsertMode::limBelow); //Размещаем на слое cursorLayer (limBelow - под слоем)
    m_customPlot->layer("cursorLayer")->setMode(QCPLayer::lmBuffered);

    //Инициализация визирной линии
    m_cursorLine = new QCPItemStraightLine(m_customPlot);
    m_cursorLine->setPen(QPen(Qt::black, 1, Qt::SolidLine));
    m_cursorLine->point1->setCoords(0, 0);
    m_cursorLine->point2->setCoords(0, 1);
    m_cursorLine->setVisible(false);
    m_cursorLine->setLayer("cursorLayer"); //Размещаем на слое cursorLayer

    m_cursorLabel = new QCPItemText(m_customPlot);
    m_cursorLabel->setPositionAlignment(Qt::AlignTop | Qt::AlignHCenter);
    m_cursorLabel->position->setParentAnchor(m_cursorLine->point1);
    m_cursorLabel->setTextAlignment(Qt::AlignCenter);
    m_cursorLabel->setFont(font);
    m_cursorLabel->setPadding(QMargins(3, 3, 3, 3));
    m_cursorLabel->position->setCoords(0, -25);
    m_cursorLabel->setBrush(QBrush(QColor(255, 250, 240, 191)));
    m_cursorLabel->setPen(QPen(Qt::blue));
    m_cursorLabel->setVisible(false);
    m_cursorLabel->setLayer("cursorLayer");

    //Легенда
    QCPLegend *legend = m_customPlot->legend;
    if (!legend) return;
    legend->setFillOrder(QCPLegend::foRowsFirst);
    legend->setBrush(QBrush(QColor(255, 250, 240, 140)));   //4 число - альфа канал
    legend->setBorderPen(QPen(Qt::NoPen));  //полностью прозрачная рамка
    legend->insertColumn(2);    //Добавляем 3 столбец для тегов
    legend->setFont(font);
    m_customPlot->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignBottom | Qt::AlignRight);
    //Настройка отступов легенды
    legend->setMargins(QMargins(2, 2, 0, 0)); //Уменьшаем отступы (left, top, right, bottom)
    legend->setRowSpacing(0);       //Вертикальный отступ между строками
    legend->setColumnSpacing(0);    //Горизонтальный отступ между колонками
    //Дополнительные настройки внутренних отступов:
    legend->setIconTextPadding(2); //Отступ между иконкой и текстом в легенде
    legend->setFillOrder(QCPLegend::foRowsFirst);  //заполнение по строкам
    legend->setMaximumSize(QWIDGETSIZE_MAX, QWIDGETSIZE_MAX);  //снять ограничения

    // legend->setIconSize(20, 10);    //Размер иконок в легенде
    qDebug() << Q_FUNC_INFO << "Initializing QCustomPlot with size:" << width() << "x" << height();
}

void CustomPlotItem::updateCustomPlotSize()
{
    if (!m_customPlot) return;
    //Проверяем, что размеры действительно валидны и больше нуля
    if (width() <= 0 || height() <= 0) return;
    m_customPlot->setGeometry(0, 0, width(), height());
    m_customPlot->setViewport(QRect(0, 0, width(), height()));
}

bool CustomPlotItem::addGraph(const QString &name, const QString &tagname)
{
    if (!m_customPlot) return false;
    if (GRAPH_SIZE <= m_customPlot->graphCount()) return false;
    auto isFirstGraph = (m_customPlot->graphCount() == 0 || m_customPlot->yAxis->label().isEmpty());

    QCPGraph *graph = m_customPlot->addGraph();
    if (!graph) return false;
    graph->setProperty("checked", false);
    graph->setProperty("tagname", tagname); //т.к. графиков не много через хэш не стал хранить
    graph->setName(QString("%1_%2").arg(QString::number(m_customPlot->graphCount()), name));

    //настройки, которые позволили убрать тормоза при перемещении графиков
    graph->setAdaptiveSampling(true); //адаптивная выборка (прореживание)
    QCPSelectionDecorator *decorator = graph->selectionDecorator(); //стиль выделенной линии
    decorator->setPen(QPen(Qt::blue, 1, Qt::DashDotLine));

    //настраиваем цвет графика
    graph->setPen(m_storeSettingGraph[settingGraphCount].color);
    graph->setScatterStyle(m_storeSettingGraph[settingGraphCount].scatter);
    settingGraphCount++;
    if (settingGraphCount >= m_storeSettingGraph.size() - 1) settingGraphCount = 0;

    //ось Y
    if (isFirstGraph) {
        //привязываем первый график к существующим осям
        graph->setKeyAxis(m_customPlot->xAxis);   //существующая ось X
        graph->setValueAxis(m_customPlot->yAxis); //существующая ось Y

        m_customPlot->yAxis->setLabel(graph->name());
        m_customPlot->yAxis->setLabelColor(graph->pen().color());
        m_customPlot->yAxis->setBasePen(graph->pen().color());
        m_customPlot->yAxis->setTickPen(graph->pen().color());
        m_customPlot->yAxis->setTickLabelColor(graph->pen().color());
        m_customPlot->yAxis->setSubTickPen(graph->pen().color());
    } else {
        QCPAxisRect *axisRect = m_customPlot->axisRect();
        QCPAxis *yAxis = new QCPAxis(axisRect, QCPAxis::atLeft);
        axisRect->addAxis(QCPAxis::atLeft, yAxis);  //Добавляем оси
        const auto axisCount = axisRect->axes(QCPAxis::atLeft).size();
        const auto offset = AXIS_SPACING * (axisCount - 1);   //Adjust multiplier as needed

        // yAxis->setPadding(-10);
        yAxis->setOffset(offset);
        yAxis->setRange(0, 5);
        yAxis->setLabel(graph->name());
        yAxis->setLabelColor(graph->pen().color());
        yAxis->setLabelPadding(m_customPlot->yAxis->labelPadding());
        yAxis->setLabelFont(m_customPlot->yAxis->labelFont());

        yAxis->setBasePen(graph->pen().color());       //цвет линии
        yAxis->setTickPen(graph->pen().color());       //основные засечки
        yAxis->setTickLabelColor(graph->pen().color());//цвет чисел
        yAxis->setTickLabelPadding(m_customPlot->yAxis->tickLabelPadding());
        yAxis->setTickLabelRotation(m_customPlot->yAxis->tickLabelRotation());
        yAxis->setTickLabelFont(m_customPlot->yAxis->tickLabelFont());
        yAxis->setSubTickPen(graph->pen().color());    //цвет стрелки

        //Сдвигаем весь QCPAxisRect вправо, чтобы ось X начиналась после всех Y
        axisRect->setMargins(QMargins(offset + 15,  //Левый отступ (основной сдвиг)
                                      0,            //Верхний отступ
                                      0,            //Правый отступ
                                      15));         //Нижний отступ (для подписей X)

        //Привязываем созданный график к нужным осям
        graph->setKeyAxis(m_customPlot->xAxis);   //Ось X (ключевая)
        graph->setValueAxis(yAxis); //Ось Y (значений)

        //connect для синхронизации движения осей
        //connect к Л-функции, рассчитываем изменение нижней границы базовой шкалы, и на это изменение перемещаем остальные оси
        QMetaObject::Connection conn = connect(m_customPlot->yAxis,
                                               static_cast<void (QCPAxis::*)(const QCPRange &, const QCPRange &)>(&QCPAxis::rangeChanged), //т.к. два сигнала QCPAxis::rangeChanged
                                               this, [this, yAxis](const QCPRange &newRange, const QCPRange &oldRange) {
                                                   auto moveY = (newRange.center() - oldRange.center()) * yAxis->range().size() / newRange.size();    //рассчитываем пермещение с учетом масштаба текущей и базовых осей
                                                   if (!m_selectedGraph) yAxis->moveRange(moveY);   //если выбран базовые график для перемещения по оси Y то отключаем перемещение всей сцены
                                                   // qDebug() << "dY" << moveY << newRange.lower;
                                               });
        //сохраняем connect в хэш (чтобы при удалении графика можно было удалить хэш
        m_hashAxisConnections.insert(yAxis, conn);
        // qDebug() << Q_FUNC_INFO << m_customPlot->graphCount() << axisCount << offset;

    }
    //Проверяем добавлен ли график в легенду, добавляем кастомные элементы
    if (m_customPlot->legend->hasItemWithPlottable(graph)) {
        emit addedGraph(graph);
    }
    if (!m_customPlot->size().isNull()) m_customPlot->replot();    //перед отрисовкой проверяем размер области, должна быть не 0, иначе crash
    return true;
}

void CustomPlotItem::removeGraph(QCPGraph *graph)
{
    if (!m_customPlot || !graph) return;
    bool isBaseAxis = false;
    QCPAxis *yAxis = graph->valueAxis();

    if (yAxis) { // Проверяем, что это не главная ось
        isBaseAxis = (yAxis == m_customPlot->yAxis);
        if (!isBaseAxis) {
            removeAxis(yAxis);
        } else {
            yAxis->setRange(0, 5);
            yAxis->setLabel("");
            yAxis->setLabelColor(QColor(Qt::black));
            yAxis->setBasePen(QPen(Qt::black));
            yAxis->setTickPen(QPen(Qt::black));
            yAxis->setTickLabelColor(Qt::black);
            yAxis->setSubTickPen(QPen(Qt::black));
        }
    }
    emit fdeletedGraph(graph->name());
    m_customPlot->removeGraph(graph); //(QCustomPlot автоматически удалит связанные оси)

    //Переносим первый график на базовую ось, если она освобождена
    if (isBaseAxis && m_customPlot->graphCount() > 0) {
        QCPGraph *firstGraph = m_customPlot->graph(0);
        if (firstGraph) {
            QCPAxis *firstAxis = firstGraph->valueAxis();
            //Удаляем старую ось, если на ней нет графиков
            if (firstAxis && firstAxis != m_customPlot->yAxis) {
                firstGraph->setValueAxis(m_customPlot->yAxis); //переносим на базовую ось
                m_customPlot->yAxis->setRange(firstAxis->range());
                m_customPlot->yAxis->setLabel(firstGraph->name());
                m_customPlot->yAxis->setLabelColor(firstGraph->pen().color());
                m_customPlot->yAxis->setBasePen(firstGraph->pen().color());
                m_customPlot->yAxis->setTickPen(firstGraph->pen().color());
                m_customPlot->yAxis->setTickLabelColor(firstGraph->pen().color());
                m_customPlot->yAxis->setSubTickPen(firstGraph->pen().color());
                if (firstAxis->graphs().isEmpty()) removeAxis(firstAxis);
            }
        }
    }
    updateAxisMargins();
    if (!m_customPlot->size().isNull()) m_customPlot->replot();
    if (m_cursorLine && m_cursorLine->visible()) createdLegend(); //если открыта визирка, перестраиваем легенду
    updateGraphDataCount();
}

void CustomPlotItem::removeAxis(QCPAxis *axis)
{
    if (!m_customPlot || !axis) return;
    m_customPlot->axisRect()->removeAxis(axis);
    //разрываем connect для данной оси
    auto connIt = m_hashAxisConnections.find(axis);
    if (connIt != m_hashAxisConnections.end()) {
        disconnect(connIt.value()); //Разрываем соединение
        m_hashAxisConnections.erase(connIt); //Удаляем из хэша
        m_hashAxisConnections.squeeze();
    }
    axis = nullptr; //QCustomPlot удаляет ось в методе removeAxis()
}

QCPGraph *CustomPlotItem::getGraphByTag(const QString &tagname)
{
    /* имена тэгов храним как свойста, т.к. графиков не много через хэш не стал делать */
    if (!m_customPlot) return nullptr;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (graph && graph->property("tagname").toString() == tagname) {
            return graph;
        }
    }
    return nullptr;
}

void CustomPlotItem::updateAxisMargins()
{
    /* обновление отступов, после удаления графика */
    if (!m_customPlot) return;
    QCPAxisRect *axisRect = m_customPlot->axisRect();
    if (!axisRect) return;

    QList<QCPAxis*> leftAxes = axisRect->axes(QCPAxis::atLeft);
    int maxOffset = 0;
    //находим максимальный отступ среди всех осей Y
    for (int i = 0; i < leftAxes.size(); ++i) {
        QCPAxis *yAxis = leftAxes[i];
        if (!yAxis) continue;
        if (yAxis != m_customPlot->yAxis) { //Игнорируем главную ось
            yAxis->setOffset(AXIS_SPACING * i);
            maxOffset = qMax(maxOffset, yAxis->offset());
        }
        yAxis->rescale(true); //Ранжируем все оси, включая базовую
    }
    //устанавливаем отступ для axisRect (область всех осей Y, для сдвига оси X в лево!)
    axisRect->setMargins(QMargins(maxOffset + 15, 0, 0, 15));
}

bool CustomPlotItem::createdLegend()
{
    if (!m_customPlot) return false;

    //cоздаем легенду, если она еще не существует
    QCPLegend *legend = m_customPlot->legend;
    if (!legend) return false;

    //очищаем существующие текстовые элементы
    for (auto &container : m_hashLegendText) {
        if (container) {
            //достаем из контейнера QCPLayoutInset сылку на текстовый элемент
            while (container->elementCount() > 0) {
                auto textElement = container->elementAt(0);
                container->remove(textElement);
            }
            legend->remove(container);
        }
    }
    m_hashLegendText.clear();
    m_hashLegendText.squeeze();

    //получаем доступ к графикам через легенду, для гарантированного соответствия строк легенды добавляемым элементам (не через for (auto i = 0; i < m_customPlot->graphCount(); ++i))
    for (auto i = 0; i < legend->rowCount(); ++i) {
        QCPAbstractLegendItem *item = legend->item(i);
        QCPPlottableLegendItem *plottableItem = qobject_cast<QCPPlottableLegendItem*>(item);
        if (plottableItem && plottableItem->plottable()) {
            QCPGraph *graph = qobject_cast<QCPGraph*>(plottableItem->plottable());
            if (!graph) continue;

            QCPTextElement *textElement = new QCPTextElement(m_customPlot);
            textElement->setLayer(legend->layer());
            textElement->setTextColor(Qt::black);
            textElement->setFont(legend->font());
            textElement->setMargins(QMargins(0, 0, 0, 0));
            textElement->setText(QString(": %1").arg(i)); //обновление данные через m_hashLegendText

            //промежуточный контейнер для выравнивания в легенде, можно сразу добавлять в легенду textElement но без выравнивания!(
            QCPLayoutInset *container = new QCPLayoutInset();
            container->addElement(textElement, Qt::AlignLeft | Qt::AlignTop);
            container->setInsetRect(0, QRectF(0.0, 0.0, 1.0, 1.0)); // Отступы в процентах
            container->setMargins(QMargins(2, 0, 2, 0));
            container->setMinimumSize(QSize(25, 10));

            legend->addElement(i, 2, container); //добавляем в легенду
            m_hashLegendText.insert(graph, container);
            qDebug() << Q_FUNC_INFO << i << graph->name();
        }
    }
    m_customPlot->plotLayout()->updateLayout();
    m_customPlot->replot();
    return true;
}

void CustomPlotItem::updateCursorPosition(const double &x)
{
    if (!m_customPlot || !m_cursorLine || !m_cursorLabel) return;

    //Ограничиваем позицию в пределах видимой области
    auto xBound = qBound(m_customPlot->xAxis->range().lower, x, m_customPlot->xAxis->range().upper);
    m_cursorLine->point1->setCoords(xBound, m_customPlot->yAxis->range().lower);
    m_cursorLine->point2->setCoords(xBound, m_customPlot->yAxis->range().upper);

    QString labelText;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (!graph) continue;
        auto data = graph->data();
        //Проверяем что указатель не пустой (убеждаемся, что контейнер существует)
        if (data.isNull() || data->isEmpty()) continue;
        auto it = data->findBegin(xBound);
        if (it != data->constEnd()) labelText = QString("%1").arg(QDateTime::fromMSecsSinceEpoch(xBound).toString("hh:mm:ss.zzz"));  //Форматируем время

        //Заполняем легенду, извлекая из Хэша указатель на нужный график
        if (m_hashLegendText.contains(graph)) {
            auto container = m_hashLegendText[graph];
            QCPLayoutElement *element = container->elementAt(0);
            QCPTextElement *textElement = qobject_cast<QCPTextElement*>(element);

            if (textElement) {
                textElement->setText(QString(" %1").arg(it->value, 0, 'f', 2)); //Оставляем Y как число с 2 знаками после запятой
                QFont font = textElement->font();
                font.setPointSize(10);
                textElement->setFont(font);
            }
        }
        // qDebug() << Q_FUNC_INFO << i << "it->value" << it->value;
    }
    m_cursorLabel->setText(labelText);
    m_customPlot->layer("cursorLayer")->replot();
    update();
}

void CustomPlotItem::handleDoubleClick()
{
    m_clickCount = 0;
    fsetCursorLine(!m_cursorVisible);
    emit fcursorLine(m_cursorVisible);
}

void CustomPlotItem::getLastData(QCPGraph *graph)
{
    if (!graph) return;
    QSharedPointer<QCPGraphDataContainer> dataContainer = graph->data();
    if (!dataContainer.isNull() && !dataContainer->isEmpty()) {
        // Получаем итератор на последний элемент
        auto lastPoint = dataContainer->constEnd() - 1;
        double lastX = lastPoint->key;
        double lastY = lastPoint->value;
        qDebug() << "Последняя точка: x =" << lastX << ", y =" << lastY;
    }
}

void CustomPlotItem::updateGraphDataCount()
{
    if (!m_customPlot) return;
    quint32 dataCount = 0;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (graph) dataCount += graph->dataCount();
    }
    emit fdataCount(dataCount);
}

void CustomPlotItem::extensionGraphLines(const double &time)
{
    /* "подтяжка графика" - при отсутствии изменений параметра и отставании графика,
     * добавляем предыдущие точки для отображения одинаковой длины на графиках */
    if (!m_customPlot) return;
    if (m_maxTimeGraph < time) m_maxTimeGraph = time;

    if (!m_throttlingGraphLines) {
        m_throttlingGraphLines = true;
        //throttling обновлений
        QTimer::singleShot(2500, this, [this]() {
            m_throttlingGraphLines = false;
            for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
                QCPGraph *graph = m_customPlot->graph(i);
                if (!graph) continue;
                QSharedPointer<QCPGraphDataContainer> data = graph->data();
                if (data->isEmpty()) continue;
                auto lastPoint = data->constEnd() - 1; //берем последний элемент
                auto lastTime  = lastPoint->key;
                //если график отстает - добавляем ему повторно последнюю точку
                if (lastTime < m_maxTimeGraph) {
                    auto pv = lastPoint->value;
                    graph->addData(m_maxTimeGraph, pv);
                }
            }
            if (!m_customPlot->size().isNull()) m_customPlot->replot(); //перед отрисовкой проверям размер области, должна быть не 0, иначе crash
        });
    }
}

void CustomPlotItem::trimToLimit(QCPGraph *graph)
{
    /* удаляем точки из начала контейнера, если достигнут лимит */
    if (graph && graph->dataCount() >= MAX_LENGTH) {
        QSharedPointer<QCPGraphDataContainer> data = graph->data();
        while (data->size() >= MAX_LENGTH) {
            if (data->isEmpty()) break;
            double firstKey = data->constBegin()->key;
            data->remove(firstKey);
        }
    }
}

void CustomPlotItem::touchEvent(QTouchEvent *event)
{
    if (!m_customPlot) return;

    switch (event->type()) {
    case QEvent::TouchBegin:
    {
        if (event->points().count() == 1) {
            const QTouchEvent::TouchPoint &point = event->points().first();
            //Создаем MousePress событие (QCoreApplication::postEvent() удалит созданное событие после обработки)
            QMouseEvent *pressEvent = new QMouseEvent(
                QEvent::MouseButtonPress,
                point.position(),
                point.globalPosition(),
                Qt::LeftButton,
                Qt::LeftButton,
                event->modifiers()
                );
            QCoreApplication::postEvent(m_customPlot, pressEvent);
        }
        m_isZoomed = false;
        //Отключаем автоматическую прокрутку после работы с Touch
        m_aScroll = false;
        emit fautoScroll(m_aScroll);
        break;
    }
    case QEvent::TouchUpdate:
    {
        const QTouchEvent::TouchPoint &point1 = event->points().first();
        const QTouchEvent::TouchPoint &point2 = event->points().last();

        //Перемещение сцены по осям XY
        if (!m_isZoomed && !m_cursorVisible && !m_selectedGraph && event->points().count() == 1) {
            //Создаем MouseMove событие (QCoreApplication::postEvent() удалит созданное событие после обработки)
            QMouseEvent *moveEvent = new QMouseEvent(
                QEvent::MouseMove,
                point1.position(),
                point1.globalPosition(),
                Qt::LeftButton,
                Qt::LeftButton,
                event->modifiers()
                );
            QCoreApplication::postEvent(m_customPlot, moveEvent);
        }
        //Перемещение выбранного графика
        if (!m_isZoomed && !m_cursorVisible && m_selectedGraph && event->points().count() == 1) {
            //Вычисляем смещение
            QPointF delta = point1.position() - point1.lastPosition();
            for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
                QCPGraph *graph = m_customPlot->graph(i);
                if (!graph) continue;
                QCPAxis *yAxis = graph->valueAxis(); //ось Y
                if (graph->property("checked").toBool()) {
                    yAxis->moveRange(delta.y() * yAxis->range().size() / yAxis->axisRect()->height());
                }
            }
            if (!m_customPlot->size().isNull()) m_customPlot->replot();
        }
        //Зумирование сцены
        if (!m_cursorVisible && event->points().count() >= 2) {
            //Вычисляем изменение расстояния между пальцами
            auto newDist = QLineF(point1.position(), point2.position()).length();
            auto oldDist = QLineF(point1.lastPosition(), point2.lastPosition()).length();

            //Вектор движения пальцев (разница между текущей и предыдущей позицией)
            QPointF delta = (point2.position() - point1.position()) - (point2.lastPosition() - point1.lastPosition());

            if (oldDist > 0 && newDist > 0)
            {
                auto scaleFactor = newDist / oldDist;
                //Масштабируем оси графика (не всю сцену!)
                //горизонтальный зум
                if (qAbs(delta.x()) > qAbs(delta.y())) m_customPlot->xAxis->scaleRange(1.0 / scaleFactor, m_customPlot->xAxis->range().center());
                // if (qAbs(delta.y()) > qAbs(delta.x())) m_customPlot->yAxis->scaleRange(1.0 / scaleFactor, m_customPlot->yAxis->range().center()); //вертикальный зум
                //вертикальный зум
                if (qAbs(delta.y()) > qAbs(delta.x())) {
                    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
                        QCPGraph *graph = m_customPlot->graph(i);
                        if (!graph) continue;
                        QCPAxis *yAxis = graph->valueAxis(); //ось Y
                        if (!m_selectedGraph) yAxis->scaleRange(1.0 / scaleFactor, yAxis->range().center()); //вся сцена
                        if (m_selectedGraph && graph->property("checked").toBool()) yAxis->scaleRange(1.0 / scaleFactor, yAxis->range().center()); //выбранный график
                    }
                }
                if (!m_customPlot->size().isNull()) m_customPlot->replot();    //перед отрисовкой проверяем размер области, должна быть не 0, иначе crash
                m_isZoomed = true;
            }
        }
        //Обновляем позицию визирной линии
        if (m_cursorVisible) {
            auto x = m_customPlot->xAxis->pixelToCoord(point1.position().x());
            updateCursorPosition(x);
        }
        break;
    }
    case QEvent::TouchEnd:
    {
        //MouseRelease событие не обрабатываем (если надо то делам так же как и MousePress)
        //Двойной клик
        m_clickCount++;
        if (m_clickCount == 1) {
            // m_clickTimer.start();
        } else if (m_clickCount >= 2) {
            // m_clickTimer.stop();
            // handleDoubleClick();
        };
        if (!m_customPlot->size().isNull()) m_customPlot->replot();    //перед отрисовкой проверям размер области, должна быть не 0, иначе crash
        // qDebug() << Q_FUNC_INFO << m_aScroll;
        break;
    }
    default:
        break;
    }
    event->accept(); //Помечаем touch-событие как обработанное (если не хотим его дальше передавать)
}

void CustomPlotItem::paint(QPainter *painter)
{
    if (m_customPlot && painter->isActive())
    {
        QPixmap picture(boundingRect().size().toSize());
        if (picture.isNull()) return;
        QCPPainter qcpPainter(&picture);
        if (!qcpPainter.isActive()) return;

        m_customPlot->toPainter(&qcpPainter);
        // setRenderTarget(QQuickPaintedItem::FramebufferObject); //Устанавливаем в конструкторе
        painter->drawPixmap(QPoint(), picture);
    }
}

bool CustomPlotItem::isModalWindowOpen()
{
    //1.Проверка окон
    const auto windows = QGuiApplication::topLevelWindows();
    for (const QWindow* window : windows) {
        // Проверяем только видимые окна с modality != NonModal
        if (window->isVisible() && window->modality() != Qt::NonModal) return true;
    }

    //2.Проверка QML элементов
    if (auto qmlWindow = window()) {
        // Ищем все объекты с modal=true и visible=true
        const auto items = qmlWindow->contentItem()->findChildren<QObject*>();
        for (QObject* obj : items) {
            if (obj->property("modal").toBool() && obj->property("visible").toBool()) return true;
        }
    }
    return false;
}

QVariant CustomPlotItem::fgetGraphList()
{
    if (!m_customPlot) return -1;
    QList<GraphParam> storeList;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (!graph) return QVariant{};
        storeList.append(GraphParam{graph->name(), graph->pen().color(), graph->property("checked").toBool()});
    }
    return QVariant::fromValue(storeList);
}

void CustomPlotItem::fsetInitPlot()
{
    initCustomPlot();
}

void CustomPlotItem::fsetAutoScroll(const bool &arg)
{
    m_aScroll = arg;
    //Отключаем визирную линии при автоскроле
    if (m_aScroll) {
        fsetCursorLine(false);
        emit fcursorLine(m_cursorVisible);
    }
}

void CustomPlotItem::fsetCursorLine(const bool &arg)
{
    m_cursorVisible = arg;
    if (createdLegend()) {
        if (!m_customPlot || !m_cursorLine || !m_cursorLabel) return;
        m_cursorLine->setVisible(m_cursorVisible);
        m_cursorLabel->setVisible(m_cursorLine->visible());
        m_customPlot->legend->setVisible(m_cursorLine->visible());

        //Активируем визирную линию и отображем в центре экрана
        if (m_cursorLine->visible()) {
            //Выводим в середину экрана
            auto x = m_customPlot->xAxis->range().upper - (m_customPlot->xAxis->range().upper - m_customPlot->xAxis->range().lower) / 2;
            updateCursorPosition(x);
        }
        m_customPlot->replot();
        qDebug() << Q_FUNC_INFO << m_cursorVisible;
    }
}

void CustomPlotItem::fsetAddGraph(const QVariant &addTag, const QVariant &name, const QVariant &tagname)
{
    bool add = addTag.toBool();
    QCPGraph *graph = getGraphByTag(tagname.toString());
    if (!graph && add) {
        if (addGraph(name.toString(), tagname.toString())) {
            TcpThread *client = TcpThread::getInstance();
            emit client->clientRequest(tagname); //формируем запрос истории с сервера
        } else {
            emit fdeletedGraph(name.toString()); //если график не добавили, испускаем сигнал, что график удален (для обновления UI)
        }
    }
    if (graph && !add) {
        removeGraph(graph);
    }
    qDebug() << Q_FUNC_INFO << add << name << tagname;
}

void CustomPlotItem::fsetSelectedGraph(const QVariant &name, const bool &checked)
{
    m_selectedGraph = false; //при первом вызове считаем что выбранных графиков нет
    if (!m_customPlot) return;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (!graph) continue;
        if (graph->name() == name.toString() && checked) {
            graph->setProperty("checked", checked);
            QPen currentPen = m_customPlot->graph(i)->pen();  //получаем текущее перо
            currentPen.setStyle(Qt::DashLine);              //меняем тип линии
            graph->setPen(currentPen);                      //ставим обратно
        }
        if (graph->name() == name.toString() && !checked) {
            graph->setProperty("checked", checked);
            QPen currentPen = m_customPlot->graph(i)->pen();  //получаем текущее перо
            currentPen.setStyle(Qt::SolidLine);             //меняем тип линии
            graph->setPen(currentPen);                      //ставим обратно
        }
        if (graph->property("checked").toBool()) m_selectedGraph = true;
    }
    m_customPlot->replot();
    if (m_selectedGraph) {
        m_customPlot->axisRect()->setRangeDrag(Qt::Horizontal);  //перемещаем только по оси X
    } else {
        m_customPlot->axisRect()->setRangeDrag(Qt::Horizontal | Qt::Vertical);
    }
    qDebug() << Q_FUNC_INFO << name << checked << "m_selectedGraph:" << m_selectedGraph;
}

void CustomPlotItem::fsetDeletedGraph(const QVariant &name)
{
    if (!m_customPlot) return;
    for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
        QCPGraph *graph = m_customPlot->graph(i);
        if (!graph) continue;
        if (graph->name() == name) {
            removeGraph(graph);
        }
    }
}

CustomPlotItem *CustomPlotItem::getInstance()
{
    /* метод для доступа к синглтону из C++
     * при получении указателя на объект, обзательно проверяем его на валидность,
     * т.к. объект создается только 1раз в Chart.qml, инициализируя "instance != nullptr" */
    return instance;
}

void CustomPlotItem::addPointsToGraph(const QVariant &tagname, const QList<TagValue> &tagValues)
{
    if (m_customPlot) {
        QCPGraph *graph = getGraphByTag(tagname.toString());
        if (!graph) return;

        graph->data().clear();
        for (const auto &tagValue : tagValues) {
            qint64 msecs = tagValue.timestamp.toDateTime().toMSecsSinceEpoch();
            double timeInMsecs = static_cast<double>(msecs);
            graph->addData(timeInMsecs, tagValue.value.toDouble());
            // graph->setData();
            // qDebug() << Q_FUNC_INFO << tagname << point.timestamp << point.pv;
        }
        trimToLimit(graph);

        QCPAxis *yAxis = graph->valueAxis();
        if (yAxis) yAxis->rescale(true);

        updateGraphDataCount();
        QSharedPointer<QCPGraphDataContainer> data = graph->data();
        if (!data->isEmpty()) {
            auto lastPoint = data->constEnd() - 1;
            auto lastTime  = lastPoint->key;   //Вычитаем предыдущее значение видимой части оси Х
            m_customPlot->xAxis->setRange(lastTime - TIME_WINDOW, lastTime);  //Пересчитываем масштаб для автоскролла
        }
        if (!m_customPlot->size().isNull()) m_customPlot->replot();    //Перед отрисовкой проверям размер области, должна быть не 0, иначе crash
    }
    // qDebug() << Q_FUNC_INFO << tagname << points.size() << points.first().timestamp << points.last().timestamp;
}

void CustomPlotItem::addPointToGraph(const QVariant &tagname, const TagValue &tagValue)
{
    if (m_customPlot) {
        QCPGraph *graph = getGraphByTag(tagname.toString());
        if (!graph) return;

        qint64 msecs = tagValue.timestamp.toDateTime().toMSecsSinceEpoch();
        double timeInMsecs = static_cast<double>(msecs);
        graph->addData(timeInMsecs, tagValue.value.toDouble());
        trimToLimit(graph);

        updateGraphDataCount();
        QSharedPointer<QCPGraphDataContainer> data = graph->data();
        if (!data->isEmpty() && m_aScroll) {
            auto lastPoint = data->constEnd() - 1; //берем последний элемент
            auto lastTime  = lastPoint->key;   //вычитаем предыдущее значение видимой части оси Х
            m_customPlot->xAxis->setRange(lastTime - TIME_WINDOW, lastTime);  //пересчитываем масштаб для автоскролла
        }
        if (!m_customPlot->size().isNull()) m_customPlot->replot(); //перед отрисовкой проверям размер области, должна быть не 0, иначе crash
        extensionGraphLines(timeInMsecs); //выравниваем остальные графики
    }
    // qDebug() << Q_FUNC_INFO << tagname << point.timestamp << point.pv;
}

void CustomPlotItem::timerEvent(QTimerEvent *event)
{
    static double U;
    U = ((double)rand() / RAND_MAX) * 5;
    double timestamp = QDateTime::currentSecsSinceEpoch(); //Unix-время в секундах

    if (m_customPlot) {
        for (auto i = 0; i < m_customPlot->graphCount(); ++i) {
            //Добавлять новые данные, если они изменились!!!!
            QCPGraph *graph = m_customPlot->graph(i);
            if (!graph) continue;
            if (graph->dataCount() <= MAX_LENGTH) {
                graph->addData(timestamp, 2 * U + i);
            }
        }
        updateGraphDataCount();

        auto range = m_customPlot->xAxis->range().upper - m_customPlot->xAxis->range().lower;
        QCPGraph *graph = m_customPlot->graph(0);
        if (!graph) return;
        QSharedPointer<QCPGraphDataContainer> data = graph->data();
        if (!data->isEmpty() && m_aScroll) {
            auto upper = data->constEnd()[-1].key + 1;
            auto lower = upper - range;   //Вычитаем предыдущее значение видимой части оси Х
            m_customPlot->xAxis->setRange(lower, upper);  //Пересчитываем масштаб для автоскролла
        }
        if (!m_customPlot->size().isNull()) m_customPlot->replot();    //Перед отрисовкой проверям размер области, должна быть не 0, иначе crash
        // qDebug() << Q_FUNC_INFO << isVisible() << m_customPlot->xAxis->range() << t;
    }
}
