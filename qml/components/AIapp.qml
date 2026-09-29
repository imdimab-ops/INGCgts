import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import InsetsHelper 1.0

Rectangle {
    id: root
    width: 175
    height: 70
    color: "#eee9e9"
    radius: 5
    border.color: "#cccccc"
    opacity: 0.75

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

    onParentControlChanged: {
        /* Контролируем измение позиции, если надо скролить и зумить со стороны родителя, меняя флаг parentControl
           В области MouseArea при обработке изменения позиции в "onPositionChanged" и вызове mouse.accepted = false
           свойство применяется только после отпускания пальца, и выполнять контроль перемещения с передачей управления
           родителю не работает, без отпусканя пальца.
           Поэтому изменение позиции контролируем со стороны родителя через флаг */
        if (parentControl) longPressTimer.stop()
    }
    //Область для обработки клика на всем баре
    MouseArea {
        id: mouseAreaChart
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        propagateComposedEvents: true

        onPressed: (mouse) => {
                       //Анимация
                       chartOnOff.scale = 0.5
                       chartOnOff.opacity = 0.5
                       longPressTimer.start()

                       //Отключаем обработку мыши и передаем контроль родителю
                       mouse.accepted = false
                       // Qt.callLater(function() {
                       //     mouse.accepted = true
                       // })
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2

        //Верхняя строка: название и позиционное обозначение
        RowLayout {
            width: parent.width
            spacing: 5

            Text {
                text: root.symbol
                font.pixelSize: 14
                color: "#777777"
                Layout.alignment: Qt.AlignVCenter  //Выравнивание по вертикали
                Layout.preferredHeight: font.pixelSize + 2 //Фиксированная высота, немного больше font.pixelSize
            }

            Text {
                text: root.name
                font.bold: true
                font.pixelSize: 14
                color: "#555555"
                Layout.alignment: Qt.AlignVCenter  //Выравнивание по вертикали
                Layout.preferredHeight: font.pixelSize + 2 //Фиксированная высота, немного больше font.pixelSize
            }

            Item {
                Layout.fillWidth: true
            }

            Image {
                id: chartOnOff
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: "/img/qmlcomponents/chartOff.svg"
                sourceSize: Qt.size(20, 20)
                visible: clickOn
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 0

                //Пульсирующая анимация (только когда не нажато)
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: !longPressTimer.running
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
            }
        }

        //Основное значение
        Text {
            id: textPV
            text: (root.lrv - 50 <= root.pv && root.pv <= root.urv + 50 && root._getBit(stw, 1) === 0) ? root.pv.toFixed(1) + " " + root.unit : "Err " + root.unit
            font.pixelSize: 28
            font.bold: true
            color: root.pvColor
            Layout.fillWidth: true
            Layout.preferredHeight: font.pixelSize + 0 //Фиксированная высота, немного больше font.pixelSize
            horizontalAlignment: Text.AlignLeft  //Выравнивание по левому краю
            verticalAlignment: Text.AlignVCenter
        }

        //Прогресс-бар для визуализации
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            radius: 5
            color: "#e0e0e0"
            Rectangle {
                id: progressBar
                width: Math.min(parent.width * (root.pv - root.lrv) / (root.urv - root.lrv), parent.width)
                height: parent.height
                radius: 5
                color: {
                    if (root._getBit(stw, 1) === 1) return "#c1cdcd" //Bad
                    if (root._getBit(stw, 3) === 1) return "#ff0000" //Alarm
                    if (root._getBit(stw, 2) === 1) return "#ffA000" //Warning
                    return "#2ecc71"
                }
                Behavior on width { NumberAnimation { duration: 50 } }

                // Дополнительная пульсация для выделенных состояний
                SequentialAnimation {
                    running: root._getBit(stw, 1) === 1 || root._getBit(stw, 2) === 1 || root._getBit(stw, 3) === 1
                    loops: Animation.Infinite

                    onStopped: {
                        //Когда анимация останавливается, сбрасываем opacity
                        progressBar.opacity = 1.0
                        textPV.opacity = 1.0
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: progressBar
                            property: "opacity"
                            from: 0.1; to: 1.0
                            duration: 750
                        }
                        NumberAnimation {
                            target: textPV
                            property: "opacity"
                            from: 0.1; to: 1.0
                            duration: 750
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: progressBar
                            property: "opacity"
                            from: 1.0; to: 0.1
                            duration: 750
                        }
                        NumberAnimation {
                            target: textPV
                            property: "opacity"
                            from: 1.0; to: 0.1
                            duration: 750
                        }
                    }
                }
            }
        }
    }
}
