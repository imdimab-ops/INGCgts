import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import InsetsHelper 1.0

Rectangle {
    id: root
    width: 200
    height: 50
    color: "#eee9e9"
    radius: 5
    border.color: "#cccccc"

    //Public свойства для настройки
    property string name: "Параметр"  // Название параметра
    property string symbol: "P1"      // Позиционное обозначение
    property real pv: 0.0             // (Process Variable) - текущее значение
    property real lrv: 0.0            // (Lower Range Value) – нижний предел шкалы измерения (0% шкалы)
    property real urv: 100.0          // (Upper Range Value) – верхний предел шкалы измерения (100% шкалы)
    property int stw: 0               // Word (0bit - rez, 1bit - Bad, 2bit - Warning, 3bit - Alarm)
    property string unit: "\u00B0C"   // Единицы измерения
    property color pvColor: "#4f4f4f" // Цвет значения
    property bool clickOn: true       // Видимость переключателя
    property bool parentControl: false  //флаг изменения позиции со стороны родителя
    property string tagname: "tag"    // Имя прочитанного тега (для запроса истории)
    signal emitAddToChart (var data)

    function updateData(data) {
        //Обновляем каждое свойство явно (т.к. передаваемая структура Q_GADGET, не имеет механизма сигналов и слотов)
        if (data) {
            pv = Number(data.pv) || 0 //Number - JavaScript - преобразуем в число ai.pv
            lrv = Number(data.lrv) || lrv
            urv = Number(data.urv) || urv
            stw = Number(data.stw) || stw
            tagname = (data.tagname) || tagname
        }
        _updateBoundaries(); //при обновлении динамически всегда обновляем границы
    }
    //Функция снятия визуализации на элементе (при удалении графика)
    function chartBtnOff(agr) {
        if (agr.includes(name)) {
            chartOnOff.source = "/img/qmlcomponents/chartOff.svg"
            _addTag = false
        }
    }

    //Private
    function _getBit(value, bitPosition) {
        return (value >> bitPosition) & 1; //сдвигаем биты числа вправо на bitPosition позиций & 1 - побитовое И с числом 1
    }

    property bool _addTag: false
    property bool _dynBoundaries: false //Динамическое построение границ
    property real _dynLrv: pv;
    property real _dynUrv: pv;
    function _updateBoundaries() {
        _dynLrv = Math.min(_dynLrv, pv - 0.1);
        _dynUrv = Math.max(_dynUrv, pv + 0.1);
    }

    onParentControlChanged: {
        /* Контролируем измение позиции, если надо скролить и зумить со стороны родителя, меняя флаг parentControl
           В области MouseArea при обработке изменения позиции в "onPositionChanged" и вызове mouse.accepted = false
           свойство применяется только после отпускания пальца, и выполнять контроль перемещения с передачей управления
           родителю не работает, без отпусканя пальца.
           Поэтому изменение позиции контролируем со стороны родителя через флаг */
        if (parentControl) longPressTimer.stop()
    }

    //Исключаем множественные обновления (при изменении каждой переменной) и обновляем 1 раз за 10мс
    Timer {
        id: updateTimer
        interval: 10
        onTriggered: progressBar.width = _getProgressWidth(progressBackground.width);
    }
    function _scheduleUpdate() {
        updateTimer.restart();
    }
    //Обработчики изменений
    onPvChanged: _scheduleUpdate()
    on_DynLrvChanged: _scheduleUpdate()
    on_DynUrvChanged: _scheduleUpdate()

    function _getProgressWidth(parentWidth) {
        var pb_width = 0;
        if (_dynBoundaries) {
            pb_width = Math.min(parentWidth * (root.pv - _dynLrv) / (_dynUrv - _dynLrv), parentWidth)
        } else {
            pb_width = Math.min(parentWidth * (root.pv - root.lrv) / (root.urv - root.lrv), parentWidth)
        }
        if (pb_width <= 2) return 2 //если делать 0 то идет кривая отрисовка
        return pb_width
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 0      // ← Явно указываем 0
            topMargin: 0    // ← Можно по отдельности
            bottomMargin: 0
            leftMargin: 1
            rightMargin: 1
        }
        spacing: 1

        //Верхняя строка: название и позиционное обозначение
        RowLayout {
            id: rowLayout
            Layout.fillWidth: true
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            spacing: 2

            Text {
                text: "(" + root.symbol + ")"
                font.pixelSize: 14
                color: "#777777"
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.name
                font.bold: true
                font.pixelSize: 14
                color: "#555555"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Image {
                id: chartOnOff
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: "/img/qmlcomponents/chartOff.svg"
                sourceSize: Qt.size(20, 20)
                visible: clickOn
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 5

                //Пульсирующая анимация (только когда не нажато)
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: !mouseAreaChart.pressed
                    ParallelAnimation {
                        NumberAnimation {
                            target: chartOnOff
                            property: "scale"
                            from: 1.0
                            to: 1.1
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: chartOnOff
                            property: "opacity"
                            from: 1.0
                            to: 0.8
                            duration: 500
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: chartOnOff
                            property: "scale"
                            from: 1.1
                            to: 1.0
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: chartOnOff
                            property: "opacity"
                            from: 0.8
                            to: 1.0
                            duration: 500
                        }
                    }
                }
                //Анимация нажатия
                Behavior on scale {NumberAnimation { duration: 100 }}
                Behavior on opacity {NumberAnimation { duration: 100 }}

                //Область для обработки клика на всем баре
                MouseArea {
                    id: mouseAreaChart
                    anchors {
                        fill: parent
                        margins: -3 //Расширяем зону клика
                    }
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                                   //Анимация
                                   chartOnOff.scale = 0.5
                                   chartOnOff.opacity = 0.5
                                   longPressTimer.start()
                                   //Отключаем обработку мыши и передаем контроль родителю
                                   mouse.accepted = false
                               }
                    onReleased: {   //после передачи контроля родителю "mouse.accepted = false" свойство "onReleased" не обрабатывется!!!
                        longPressTimer.stop()
                        console.log("onReleased", enabled)
                    }
                }
                Timer {
                    id: longPressTimer
                    interval: 800
                    repeat: false
                    onTriggered: {
                        _addTag = !_addTag
                        chartOnOff.source = _addTag ? "/img/qmlcomponents/chartOn.svg" : "/img/qmlcomponents/chartOff.svg"
                        InsetsHelper.vibrateAndroid(100);

                        var data = {
                            name: name,
                            symbol: symbol,
                            tagname: tagname,
                            addTag: _addTag
                        }
                        emitAddToChart(data)
                    }
                }
            }

            Image {
                id: switchIcon
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: "/img/qmlcomponents/rotate_right.svg"
                sourceSize: Qt.size(20, 20)
                visible: clickOn
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 5

                //Пульсирующая анимация (только когда не нажато)
                SequentialAnimation {
                    id: pulseAnimation
                    loops: Animation.Infinite
                    running: !longPressTimer.running
                    ParallelAnimation {
                        NumberAnimation {
                            target: switchIcon
                            property: "scale"
                            from: 1.0
                            to: 1.1
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: switchIcon
                            property: "opacity"
                            from: 1.0
                            to: 0.8
                            duration: 500
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: switchIcon
                            property: "scale"
                            from: 1.1
                            to: 1.0
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: switchIcon
                            property: "opacity"
                            from: 0.8
                            to: 1.0
                            duration: 500
                        }
                    }
                }
                //Анимация нажатия
                Behavior on scale {NumberAnimation { duration: 100 }}
                Behavior on opacity {NumberAnimation { duration: 100 }}

                //Область для обработки кликов
                MouseArea {
                    id: mouseArea
                    anchors {
                        fill: parent
                        margins: -3 //Расширяем зону клика
                    }
                    cursorShape: Qt.PointingHandCursor
                    onPressedChanged: {
                        if (pressed) {
                            //Анимация при нажатии - уменьшение и затемнение
                            switchIcon.scale = 0.5
                            switchIcon.opacity = 0.5
                            progressBarContainer.flip()
                            root._dynBoundaries = !root._dynBoundaries
                            InsetsHelper.vibrateAndroid(50);
                        } else {
                            //Анимация при отпускании - возврат к нормальному состоянию
                            switchIcon.scale = 1.0
                            switchIcon.opacity = 1.0
                        }
                        _scheduleUpdate() //при нажатии сразу перестраиваем границы
                    }
                }
            }
        }

        //Прогресс-бар с текстом значения внутри
        Item {
            id: progressBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            //Фон прогресс-бара
            Rectangle {
                id: progressBackground
                anchors.fill: parent
                radius: 5
                color: "#e0e0e0"
                onWidthChanged: root._scheduleUpdate()  // Обработчики изменений

                //Заполненная часть прогресс-бара
                Rectangle {
                    id: progressBar
                    //width: Math.min(parentWidth * (root.pv - root.lrv) / (root.urv - root.lrv), parentWidth)
                    height: parent.height
                    radius: 5
                    scale: 1.0

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            id: grad1
                            position: 0.0
                            color: {
                                if (root._getBit(stw, 1) === 1) return "#c1cdcd" //Bad
                                if (root._getBit(stw, 3) === 1) return "#ff0000" //Alarm
                                if (root._getBit(stw, 2) === 1) return "#ffA000" //Warning
                                return "#2ecc71";
                            }
                        }
                        GradientStop {
                            id: grad2
                            position: 0.5
                            color: {
                                if (root._getBit(stw, 1) === 1) return "#b4c2c2" //Bad
                                if (root._getBit(stw, 3) === 1) return "#e60000" //Alarm
                                if (root._getBit(stw, 2) === 1) return "#ff8c00" //Warning
                                return "#29b765";
                            }
                        }
                        GradientStop {
                            id: grad3
                            position: 1.0
                            color: {
                                if (root._getBit(stw, 1) === 1) return "#a7b7b7" //Bad
                                if (root._getBit(stw, 3) === 1) return "#cc0000" //Alarm
                                if (root._getBit(stw, 2) === 1) return "#ff7800" //Warning
                                return "#27ae60";
                            }
                        }
                    }
                    Behavior on width { NumberAnimation { duration: 50 } }

                    //Динамичная анимация перелива
                    SequentialAnimation {
                        running: true
                        loops: Animation.Infinite
                        ParallelAnimation {
                            NumberAnimation {
                                target: grad1
                                property: "position"
                                from: 0.0; to: 1.0
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: grad2
                                property: "position"
                                from: 0.33; to: 1.0
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: grad3
                                property: "position"
                                from: 0.66; to: 1.0
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: grad1
                                property: "position"
                                from: 1.0; to: 0.0
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: grad2
                                property: "position"
                                from: 1.0; to: 0.33
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: grad3
                                property: "position"
                                from: 1.0; to: 0.66
                                duration: 5000
                                easing.type: Easing.InOutSine
                            }
                        }
                        PauseAnimation {
                            duration: 500  //Добавляем небольшую паузу между циклами
                        }
                    }

                    //Дополнительная пульсация для выделенных состояний
                    SequentialAnimation {
                        running: root._getBit(stw, 1) === 1 || root._getBit(stw, 2) === 1 || root._getBit(stw, 3) === 1
                        loops: Animation.Infinite

                        onStopped: {
                            // Когда анимация останавливается, сбрасываем opacity
                            progressBar.opacity = 1.0
                        }

                        NumberAnimation {
                            target: progressBar
                            property: "opacity"
                            from: 0.1; to: 1.0
                            duration: 750
                        }
                        NumberAnimation {
                            target: progressBar
                            property: "opacity"
                            from: 1.0; to: 0.1
                            duration: 750
                        }
                    }

                    //Анимация поворота при нажатии
                    transform: Rotation {
                        id: rotation
                        origin.x: progressBar.width / 2
                        origin.y: progressBar.height / 2
                        axis { x: 0; y: 0; z: 1 }
                        angle: 0
                    }
                }

                //Текст значения поверх прогресс-бара
                Text {
                    text: (root.lrv - 50 <= root.pv && root.pv <= root.urv + 50 && root._getBit(stw, 1) === 0) ? root.pv.toFixed(1) + " " + root.unit : root.pv.toFixed(1) + " " + root.unit + " Err"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.pvColor
                    anchors.centerIn: parent
                    Layout.fillWidth: true
                    Layout.preferredHeight: font.pixelSize + 0 // Фиксированная высота, немного больше font.pixelSize
                    horizontalAlignment: Text.AlignLeft  // Выравнивание по левому краю
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: _dynBoundaries ? root._dynLrv.toFixed(1) : root.lrv.toFixed(1) //toFixed(1) 1 число после запятой
                    font.pixelSize: 10
                    font.bold: true
                    color: root.pvColor
                    anchors {
                        left: parent.left
                        leftMargin: progressBackground.radius
                        verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    text: _dynBoundaries ? root._dynUrv.toFixed(1) : root.urv.toFixed(1)
                    font.pixelSize: 10
                    font.bold: true
                    color: root.pvColor
                    anchors {
                        right: parent.right
                        rightMargin: progressBackground.radius
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
            //Функция для запуска анимации
            function flip() {
                if (flipAnimation.running) return;
                flipAnimation.start();
            }

            //Анимация поворота
            SequentialAnimation {
                id: flipAnimation
                ParallelAnimation {
                    NumberAnimation {
                        target: rotation
                        property: "angle"
                        from: 0
                        to: 180
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: progressBar
                        property: "scale"
                        from: 1.0
                        to: 0.8
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                }
                NumberAnimation {
                    target: progressBar
                    property: "scale"
                    from: 0.8
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                }
            }
        }
    }
}
