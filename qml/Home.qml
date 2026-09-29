import QtQuick 2.15
import QtQuick.Controls 6.2
import QtQuick.Window 2.15
import QtQuick.Layouts
import QtQuick.Shapes 1.9
import CustomPlot 1.0
import "./components"


//Перемещаем изображение после масштабирования
Item {
    id: root
    anchors.fill: parent

    Connections {
        target: appEng
        function onFdataUpdate(arg) {
            aiPT908.updateData(arg.PT908)
            aiAT901.updateData(arg.AT901)
            aiTT203.updateData(arg.TT203)
            aiTT205.updateData(arg.TT205)
            aiTT704.updateData(arg.TT704)
            aiTE601.updateData(arg.TE601)
            aiTT901.updateData(arg.TT901)
            aiTT903.updateData(arg.TT903)
            aiTE71.updateData(arg.TE71)
            pbST50.updateData(arg.ST50)
            pbF72.updateData(arg.F72)
            // pbGenP.updateData(name)
            // pbGenU.updateData(name)
            // pbGenF.updateData(name)
            pbWRKTM.updateData(arg.WRKTM)

            _smokeOn = Number(arg.TE71.pv) >= 200;
        }
    }

    property var _globalPlot: appEng.fgetCustomPlot()
    Connections {
        target: _globalPlot
        function onFdeletedGraph(name) {
            aiPT908.chartBtnOff(name)
            aiAT901.chartBtnOff(name)
            aiTT203.chartBtnOff(name)
            aiTT205.chartBtnOff(name)
            aiTT704.chartBtnOff(name)
            aiTE601.chartBtnOff(name)
            aiTT901.chartBtnOff(name)
            aiTT903.chartBtnOff(name)
            aiTE71.chartBtnOff(name)
            pbST50.chartBtnOff(name)
            pbF72.chartBtnOff(name)
            pbGenP.chartBtnOff(name)
            pbGenU.chartBtnOff(name)
            pbGenF.chartBtnOff(name)
        }
    }
    function _addCharForPlot (data) {
        _globalPlot = appEng.fgetCustomPlot()
        if (_globalPlot) {
            _globalPlot.fsetAddGraph(data.addTag, data.name, data.tagname)
        } else {
            console.error("CustomPlotSingleton is null!")
        }
    }

    MultiTouchRect {
        id: multiTouch
        anchors.fill: parent
        maxScale: 1.0
        minScale: 0.3
        defaultScale: 0.3
        speedScale: 0.5
        zoomedScaleDoubleClick: 0.65
        imageContainer: imageContainer
        mainRoot: root
    }

    property bool _smokeOn : false

    //Параллельная анимация для плавного масштабирования и перемещения
    ParallelAnimation {
        id: zoomAnimation
        NumberAnimation {
            target: imageScale
            properties: "xScale,yScale"
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "imagePosition.x"
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "imagePosition.y"
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
    //Анимация возврата в исходное состояние
    ParallelAnimation {
        id: resetAnimation
        NumberAnimation {
            target: imageScale
            properties: "xScale,yScale"
            to: 1.0  // Возврат к исходному масштабу
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "imagePosition.x"
            to: 0
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "imagePosition.y"
            to: 0
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    //Контейнер для изображения с трансформациями
    Item {
        id: imageContainer
        anchors {
            top: parent.top
            topMargin: 0  // Отступ сверху 15px
            horizontalCenter: parent.horizontalCenter
        }
        width: imgBlock1.implicitWidth
        height: imgBlock1.implicitHeight

        transform: Matrix4x4 {
            id: imageScale
            property real scale: multiTouch.zoomedScale
            property real userX: multiTouch.imagePosition.x  //Смещение X от пользователя
            property real userY: multiTouch.imagePosition.y  //Смещение Y от пользователя

            property real originX: (multiTouch.zoomCenter.x !== 0) ? multiTouch.zoomCenter.x - imageContainer.x : imageContainer.width/2    //масштабируем относительно средней точки прикосновения пальцев
            property real originY: (multiTouch.zoomCenter.y !== 0) ? multiTouch.zoomCenter.y - imageContainer.y : 0

            property real m14: originX * (1 - scale) + userX * scale
            property real m24: originY * (1 - scale) + userY * scale

            matrix: Qt.matrix4x4(
                        scale, 0, 0, m14,
                        0, scale, 0, m24,
                        0, 0, 1, 0,
                        0, 0, 0, 1
                        )
        }

        Image {
            id: imgBlock1
            anchors.centerIn: parent
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/home/block.png"
            //После загрузки изображения рассчитываем на сколько сдвинуть нижний ColumnLayout
            onStatusChanged: if (status === Image.Ready) {columnAI.calculateMappedPos()}

            /* Убрал, чтобы не отбражалась рамка поля с изображением! */
            // Rectangle {
            //     anchors.fill: parent
            //     color: "transparent"
            //     border.color: "#cccccc"
            //     border.width: 1
            //     radius: 5 / imageScale.xScale
            // }
        }
        //Наложение анимированного GIF
        AnimatedImage {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/logo_slow.gif"
            sourceSize: Qt.size(125, 125)
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать к температуре в КС !!!!!!)
            visible: true
            anchors {
                top: imgBlock1.top
                topMargin: 10  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 10  //Отступ слева 20px
            }
        }

        AnimatedImage {
            id: imgSmoke
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/home/smoke.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: _smokeOn
            anchors {
                top: imgBlock1.top
                topMargin: -90  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 210  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 280
            opacity: 0.5  //Полупрозрачность (0.0 - 1.0)
        }

        //Текстовый элемент, который будет масштабироваться вместе с изображением
        Text {
            text: "Блоки ГТЭА"
            color: "#333333" //Более мягкий серый вместо чистого "grey"
            font {
                pixelSize: 28
                weight: Font.Medium
                family: "SF Pro Display, Roboto, Arial"
            }
            style: Text.Outline
            styleColor: "#f0f0f0" //Более светлый контур вместо черного
            opacity: 0.9 //Легкая прозрачность
            anchors {
                top: imgBlock1.top
                horizontalCenter: imgBlock1.horizontalCenter
                topMargin: 15  //Отступ сверху 15px
            }
        }

        AIapp {
            id: aiPT908
            name: "Pатм"
            symbol: "PT908"
            pv: 0
            unit: "кПа"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 175  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 20  //Отступ слева 20px
            }
        }

        AIapp {
            id: aiAT901
            name: "Влажность"
            symbol: "АТ901"
            pv: 0
            unit: "%"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 250  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 20  //Отступ слева 20px
            }
        }

        AIapp {
            id: aiTT903
            name: "Татм"
            symbol: "TT903"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 250  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 200  //Отступ слева 20px
            }
        }

        AIapp {
            id: aiTT203
            name: "Тсекц АВОМ"
            symbol: "TT203"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 400  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 20  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTT203.x + aiTT203.width     //начало выноски
                startY: aiTT203.y + aiTT203.height
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 - 375    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 100
                }
            }
        }

        AIapp {
            id: aiTT901
            name: "Твх.компр"
            symbol: "TT901"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 150  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 425  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTT901.x + aiTT901.width / 2     //начало выноски
                startY: aiTT901.y + aiTT901.height
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 + 90    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 125
                }
            }
        }

        AIapp {
            id: aiTT704
            name: "Твых.воздуха"
            symbol: "TT704"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 150  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 625  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTT704.x + aiTT704.width     //начало выноски
                startY: aiTT704.y + aiTT704.height
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 + 250    //конец выноски
                    y: imgBlock1.y + 300
                }
            }
        }

        AIapp {
            id: aiTE601
            name: "Твоздуха"
            symbol: "TЕ601"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 20  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 20  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTE601.x + aiTE601.width     //начало выноски
                startY: aiTE601.y
                PathLine {
                    x: imgBlock1.x + 300    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 250
                }
            }
        }

        AIapp {
            id: aiTT205
            name: "Тм.вых АВОМ"
            symbol: "TT205"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 20  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 725  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTT205.x + aiTT205.width / 2     //начало выноски
                startY: aiTT205.y
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 + 120    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 170
                }
            }
        }

        AIapp {
            id: aiTE71
            name: "Tвыхлопа"
            symbol: "TE71"
            pv: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 150  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 1085  //Отступ слева 20px
            }
        }
    }

    //Column аналоговых параметров
    ColumnLayout {
        id: columnAI
        //Динамически изменяем spacing в зависимости от координаты y
        property real defaultSpacing: 2
        spacing: defaultSpacing
        anchors {
            topMargin: 10
            left: parent.left
            leftMargin: 10  //Отступ слева 20px
            right: parent.right
            rightMargin: 10 //Отступ слева 20px
        }
        //Позиционирование с учетом трансформаций imageContainer
        y: mappedPos.y
        //Добавляем плавность анимации
        Behavior on spacing {NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        property point mappedPos: Qt.point(0, 0)
        property bool updating: false   //Флаг для блокировки рекурсивных обновлений
        property real prevY: 0
        function calculateMappedPos() {
            if (columnAI.updating) return;
            columnAI.updating = true;
            //Откладываем до следующего цикла событий, чтобы успел перерисоваться новый масштаб
            //Иначе новая позиция пересчитывается в момент изменения масштаба и объект columnAI остается где то по середине экрана
            Qt.callLater(function() {
                var newPos = imageContainer.mapToItem(root, 0, imageContainer.height + 10)
                //Определяем движение
                var deltaY = newPos.y - prevY
                prevY = newPos.y
                if (Math.abs(deltaY) > 1) { //Порог для определения движения
                    //Уменьшаем spacing при движении вниз, увеличиваем при движении вверх
                    spacing = defaultSpacing * (deltaY > 0 ? 0.5 : 4)
                    updateTimer.restart()
                }
                columnAI.mappedPos = newPos
                columnAI.updating = false
            })
        }
        //Через таймер сбрасываем spacing, т.к. при изменении Зума функция calculateMappedPos повторно не асегда вызывается
        Timer {
            id: updateTimer
            interval: 10
            onTriggered: {
                columnAI.spacing = columnAI.defaultSpacing
            }
        }

        //Коннекты для обновления позции при изменении положения
        Connections {
            target: multiTouch
            function onZoomedScaleChanged() { columnAI.calculateMappedPos() }
            function onImagePositionChanged() { columnAI.calculateMappedPos() }
        }

        Text {
            text: "Рабочие показатели:"
            color: "#333333" //Более мягкий серый вместо чистого "grey"
            font {
                pixelSize: 18
                weight: Font.Medium
                family: "SF Pro Display, Roboto, Arial"
            }
            style: Text.Outline
            styleColor: "#f0f0f0" //Более светлый контур вместо черного
            opacity: 1.0 //Легкая прозрачность
            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: 10
            Layout.bottomMargin: 5
        }

        AIpb {
            id: pbST50
            name: "Обороты турбины"
            symbol: "ST50"
            unit: "об/мин"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbF72
            name: "Обороты генератора"
            symbol: "F72"
            urv: 2000
            unit: "об/мин"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbGenP
            name: "Мощность"
            symbol: "P"
            unit: "кВт"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbGenU
            name: "Напряжение"
            symbol: "U"
            unit: "В"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbGenF
            name: "Частота"
            symbol: "FREQ"
            unit: "Гц"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            name: "Сгенерировано за сутки"
            symbol: "Gen"
            unit: "кВт/ч"
            parentControl: multiTouch.grabPosition
            clickOn: false
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbWRKTM
            name: "Наработка"
            symbol: "Time"
            unit: "ч"
            lrv: (urv - 5000 < 0) ? 0 : urv - 5000;
            urv: (pv <= 0) ? 5000 : Math.ceil(pv / 5000) * 5000  //Округление ВВЕРХ до ближайшей 5000
            parentControl: multiTouch.grabPosition
            clickOn: false
            Layout.fillWidth: true  //Позиционирование с отступами
        }
    }
}
