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
            //GTU
            aiST50.updateData(arg.ST50)
            aiFC424.updateData(arg.FC424)
            aiKC1.updateData(arg.KC1)
            aiKC2.updateData(arg.KC2)
            aiKC3.updateData(arg.KC3)
            aiKC4.updateData(arg.KC4)
            aiKC5.updateData(arg.KC5)
            //Reductor
            aiTE576.updateData(arg.TE576)
            aiTE577.updateData(arg.TE577)
            aiTE578.updateData(arg.TE578)
            aiTE579.updateData(arg.TE579)
            aiTE580.updateData(arg.TE580)
            aiTE581.updateData(arg.TE581)
            //GEN
            aiTFU.updateData(arg.TFU)
            aiTFV.updateData(arg.TFV)
            aiTFW.updateData(arg.TFW)
            aiTnde.updateData(arg.Tnde)
            aiTde.updateData(arg.Tde)

            aiTT205.updateData(arg.TT205)

            pbST50.updateData(arg.ST50)
            pbFT901.updateData(arg.FT901)
            pbPT701.updateData(arg.PT701)
            pbTE701.updateData(arg.TE701)
            pbTE71.updateData(arg.TE71)
            //Fuel
            pbFV401_2.updateData(arg.FV401_2)
            pbFC424.updateData(arg.FC424)
            pbPT403.updateData(arg.PT403)
            pbTT401.updateData(arg.TT401)

            _rotateOn = Number(arg.ST50.pv) >= 300;
            _fireOn =  Number(arg.TE71.pv) >= 170;
        }
    }

    property var _globalPlot: appEng.fgetCustomPlot()
    Connections {
        target: _globalPlot
        function onFdeletedGraph(name) {
            aiST50.chartBtnOff(name)
            aiFC424.chartBtnOff(name)
            aiKC1.chartBtnOff(name)
            aiKC2.chartBtnOff(name)
            aiKC3.chartBtnOff(name)
            aiKC4.chartBtnOff(name)
            aiKC5.chartBtnOff(name)
            //Reductor
            aiTE576.chartBtnOff(name)
            aiTE577.chartBtnOff(name)
            aiTE578.chartBtnOff(name)
            aiTE579.chartBtnOff(name)
            aiTE580.chartBtnOff(name)
            aiTE581.chartBtnOff(name)
            //GEN
            aiTFU.chartBtnOff(name)
            aiTFV.chartBtnOff(name)
            aiTFW.chartBtnOff(name)
            aiTnde.chartBtnOff(name)
            aiTde.chartBtnOff(name)

            aiTT205.chartBtnOff(name)

            pbST50.chartBtnOff(name)
            pbFT901.chartBtnOff(name)
            pbPT701.chartBtnOff(name)
            pbTE701.chartBtnOff(name)
            pbTE71.chartBtnOff(name)
            //Fuel
            pbFV401_2.chartBtnOff(name)
            pbFC424.chartBtnOff(name)
            pbPT403.chartBtnOff(name)
            pbTT401.chartBtnOff(name)
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
        speedScale: 0.7
        zoomedScaleDoubleClick: 0.65
        imageContainer: imageContainer
        mainRoot: root
    }

    property bool _rotateOn : false
    property bool _fireOn : false

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
            to: 1.0  //Возврат к исходному масштабу
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

        //Выравнивание у верхнего края с центровкой по горизонтали
        anchors {
            top: parent.top
            topMargin: 0  // Отступ сверху 15px
            horizontalCenter: parent.horizontalCenter
        }

        width: imgBlock1.implicitWidth
        height: imgBlock1.implicitHeight

        // transform: [
        //     Translate { id: imageTranslate
        //         x: multiTouch.imagePosition.x
        //         y: multiTouch.imagePosition.y
        //     },
        //     Scale {
        //         id: imageScale
        //         origin.x : (multiTouch.zoomCenter.x !== 0) ? multiTouch.zoomCenter.x - imageContainer.x : imageContainer.width/2    //масштабируем относительно средней точки прикосновения пальцев
        //         origin.y : (multiTouch.zoomCenter.y !== 0) ? multiTouch.zoomCenter.y - imageContainer.y: 0
        //         xScale: multiTouch.zoomedScale
        //         yScale: multiTouch.zoomedScale
        //     }
        // ]

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
            source: "/img/gtu/base.svg"
            sourceSize: Qt.size(1280, 1041) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
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
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: true
            anchors {
                top: imgBlock1.top
                topMargin: 10  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 10  //Отступ слева 20px
            }
        }

        AnimatedImage {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/rotate.gif"
            sourceSize: Qt.size(475, 250)
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: _rotateOn
            scale: 0.90
            anchors {
                top: imgBlock1.top
                topMargin: 575
                left: imgBlock1.left
                leftMargin: 497
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 0
            opacity: 1.0  //Полупрозрачность (0.0 - 1.0)
        }

        //Камера сгорания
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/cam1.svg"
            sourceSize: Qt.size(225, 115) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 660  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 252  //Отступ слева 20px
            }
        }
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/cam1.svg"
            sourceSize: Qt.size(225, 115) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 543  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 252  //Отступ слева 20px
            }
        }
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/cam2.svg"
            sourceSize: Qt.size(235, 154) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 390  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 252  //Отступ слева 20px
            }
        }
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/cam3.svg"
            sourceSize: Qt.size(235, 154) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 140  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 252  //Отступ слева 20px
            }
        }
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/cam4.svg"
            sourceSize: Qt.size(225, 115) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 22  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 252  //Отступ слева 20px
            }
        }
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/turboFireEx.svg"
            sourceSize: Qt.size(375, 225) //Указываем явный размер, иначе Qt уменьшает SVG до размера экрана при загрузке
            visible: _fireOn
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 228  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 40  //Отступ слева 20px
            }
        }
        AnimatedImage {
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/firecam.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: Number(aiKC1.pv >= 180) && _rotateOn
            scale: 0.7
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 600  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 230  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 270
            opacity: 0.9  //Полупрозрачность (0.0 - 1.0)
        }
        AnimatedImage {
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/firecam.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: Number(aiKC2.pv >= 180) && _rotateOn
            scale: 0.7
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 480  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 230  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 270
            opacity: 0.9  //Полупрозрачность (0.0 - 1.0)
        }
        AnimatedImage {
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/firecam.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: Number(aiKC3.pv >= 180) && _rotateOn
            scale: 0.7
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 363  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 230  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 270
            opacity: 0.9  //Полупрозрачность (0.0 - 1.0)
        }
        AnimatedImage {
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/firecam.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: Number(aiKC4.pv >= 180) && _rotateOn
            scale: 0.7
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 28  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 230  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 270
            opacity: 0.9  //Полупрозрачность (0.0 - 1.0)
        }
        AnimatedImage {
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/firecam.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: Number(aiKC5.pv >= 180) && _rotateOn
            scale: 0.7
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: -92  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 230  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 270
            opacity: 0.9  //Полупрозрачность (0.0 - 1.0)
        }
        AnimatedImage {
            z: -1
            width: 300
            height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "/img/gtu/fire.gif"
            playing: true  //Автоматическое воспроизведение (!!!!!! Привязать в температуре в КС !!!!!!)
            visible: _fireOn && _rotateOn
            scale: 1.2
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 195  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: -90  //Отступ слева 20px
            }

            //Если нужно вращение вокруг центра (по умолчанию вращение вокруг (0,0))
            transformOrigin: Item.Center  //Вращение вокруг центра элемента
            rotation: 90
            opacity: 1.0  //Полупрозрачность (0.0 - 1.0)
        }

        //Текстовый элемент, который будет масштабироваться вместе с изображением
        Text {
            text: "Параметры турбины"
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
            id: aiST50
            name: "Обороты турб"
            symbol: "ST50"
            pv: 0
            lrv: 0
            urv: 30000
            stw: 0
            unit: "об"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 305  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 160  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiFC424
            name: "Расход ТГ"
            symbol: "FT421"
            pv: 0
            lrv: 0
            urv: 1200
            stw: 0
            unit: "г/с"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 85  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 200  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiKC1
            name: "Т в КС1"
            symbol: "KC1"
            pv: 24.7
            lrv: 0
            urv: 900
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 270  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 525  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiKC2
            name: "Т в КС2"
            symbol: "KC2"
            pv: 24.7
            lrv: 0
            urv: 900
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 390  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 525  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiKC3
            name: "Т в КС3"
            symbol: "KC3"
            pv: 24.7
            lrv: 0
            urv: 900
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 510  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 525  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiKC4
            name: "Т в КС4"
            symbol: "KC4"
            pv: 24.7
            lrv: 0
            urv: 900
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 830  //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 525  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiKC5
            name: "Т в КС5"
            symbol: "KC5"
            pv: 24.7
            lrv: 0
            urv: 900
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 950 //Отступ сверху 15px
                right: imgBlock1.right
                rightMargin: 525  //Отступ слева 20px
            }
        }
        //Редуктор
        AIapp {
            id: aiTE576
            name: "Тпл.ряда т.1"
            symbol: "TE576"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 320 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 390  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTE577
            name: "Тпл.ряда т.2"
            symbol: "TE577"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 400 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 390  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTE578
            name: "Тпл.ряда т.3"
            symbol: "TE578"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 480  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 390  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTE578.x + aiTE578.width / 2     //начало выноски
                startY: aiTE578.y + aiTE578.height
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 - 130    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 180
                }
            }
        }
        AIapp {
            id: aiTE579
            name: "Тпл.ряда т.1"
            symbol: "TE579"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 320 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 210  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTE580
            name: "Тпл.ряда т.2"
            symbol: "TE580"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 400 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 210  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTE581
            name: "Тпл.ряда т.3"
            symbol: "TE581"
            pv: 20.7
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 480  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 210  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTE581.x + aiTE581.width / 2     //начало выноски
                startY: aiTE581.y + aiTE581.height
                PathLine {
                    x: imgBlock1.x + imgBlock1.width / 2 - 185    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 180
                }
            }
        }
        AIapp {
            id: aiTT205
            name: "Тм.вых АВОМ"
            symbol: "TT205"
            pv: 87.6
            lrv: -50
            urv: 100
            stw: 3
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 90  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 325  //Отступ слева 20px
            }
        }

        //Генератор
        AIapp {
            id: aiTFU
            name: "Тфазы U"
            symbol: "TE590"
            pv: 20.7
            lrv: 0
            urv: 200
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 320 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 15  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTFV
            name: "Тфазы V"
            symbol: "TE592"
            pv: 20.7
            lrv: 0
            urv: 200
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 400 //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 15  //Отступ слева 20px
            }
        }
        AIapp {
            id: aiTFW
            name: "Тфазы W"
            symbol: "TE594"
            pv: 20.7
            lrv: 0
            urv: 200
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                top: imgBlock1.top
                topMargin: 480  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 15  //Отступ слева 20px
            }
        }

        AIapp {
            id: aiTnde
            name: "Tnde"
            symbol: "TE596"
            pv: 78.4
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 130  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 80  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTnde.x
                startY: aiTnde.y
                PathLine {
                    x: imgBlock1.x + 30    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 180
                }
            }
        }

        AIapp {
            id: aiTde
            name: "Tde"
            symbol: "TE597"
            pv: 78.4
            lrv: 0
            urv: 150
            stw: 0
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            anchors {
                bottom: imgBlock1.bottom
                bottomMargin: 50  //Отступ сверху 15px
                left: imgBlock1.left
                leftMargin: 80  //Отступ слева 20px
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 2
                strokeColor: "red"
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: aiTde.x + aiTde.width    //начало выноски
                startY: aiTde.y
                PathLine {
                    x: imgBlock1.x + 340    //конец выноски
                    y: imgBlock1.y + imgBlock1.height / 2 + 180
                }
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
            id: pbFV401_2
            name: "Дозатор топлива"
            symbol: "FV401_2"
            unit: "%"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbFC424
            name: "Расход топлива"
            symbol: "FC424"
            unit: "г/с"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbPT403
            name: "Давление топлива"
            symbol: "PT403"
            unit: "МПа"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbTT401
            name: "Температура топлива"
            symbol: "TT401"
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbFT901
            name: "Расход воздуха на входе в компр."
            symbol: "FT901"
            unit: "кг/с"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbPT701
            name: "Давление воздуха за компр."
            symbol: "PT701"
            unit: "МПа"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbTE701
            name: "Температура воздуха за компр."
            symbol: "TE701"
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
        AIpb {
            id: pbTE71
            name: "Температура выхлопа"
            symbol: "TE71"
            unit: "\u00B0C"
            parentControl: multiTouch.grabPosition
            onEmitAddToChart: (data)=> {
                                  _addCharForPlot(data)
                              }
            Layout.fillWidth: true  //Позиционирование с отступами
        }
    }
}
