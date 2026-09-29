import QtQuick 2.15
import QtQuick.Controls 6.2

//MultiTouchRect.qml - обработка зума только той области, где расположено изображение, перемещения по всей области экрана

//MultiPointTouchArea для обработки мультитач-жестов
MultiPointTouchArea {
    id: touchArea
    anchors.fill: parent
    minimumTouchPoints: 1
    maximumTouchPoints: 2
    mouseEnabled: true //для обработки мыши в десктопном режиме

    //public
    property real maxScale: 1.8
    property real minScale: 0.3
    property real defaultScale: 0.3                 //нормальный масштаб для отображения (по умолчанию)
    property real zoomedScale: 1.0                  //текущий масштаб
    property real zoomedScaleDoubleClick: 1.0       //изменение масштаба при двойном клике
    property real speedScale: 1.0                   //скорость изменения масштаба
    property point imagePosition: Qt.point(0, 0)    //позиция изображения в абсолютных координатах (реальные координаты без учета трансформации, тут трансформации не применяюся)
    property point zoomCenter: Qt.point(0, 0)       //центр координат, относительно которого зумируем
    property var imageContainer //"указатель" на контейнер с изображением, который трансформируем (imageContainer не учитывает трансформации, imageContainer.width/height - всегда постоянны)
    property var mainRoot       //"указатель" на область в которой находится imageContainer
    property bool grabPosition: false            //флаг изменения позииции (использую для признака работы MultiPointTouchArea, если среди детей есть обработка Touch (AI.qml))

    //private
    property real _initialDistance: 0
    property point _initialCenter: Qt.point(0, 0)
    property point _initialPosition: Qt.point(0, 0)
    property point _newXY: Qt.point(0, 0)

    property bool _initia: false    //инициализируем мультитач жесты
    property int _clickCount: 0

    Component.onCompleted: {
        zoomedScale = defaultScale
    }

    //Одиночный клик
    Timer {
        id: clickTimer
        interval: 300 // Интервал для двойного клика (мс)
        onTriggered: {
            parent._clickCount = 0
            // console.log("Одиночный клик")
        }
    }

    //Двойной клик
    function _handleDoubleClick() {
        _clickCount = 0
        if (zoomedScale === defaultScale) {
            zoomedScale = zoomedScaleDoubleClick
        } else {
            zoomedScale = defaultScale
        }

        imagePosition.x = 0 //масштабируем относительно центра экрана
        imagePosition.y = 0
        zoomCenter.x = 0
        zoomCenter.y = 0
        // console.log("Двойной клик!")
    }

    //Ограничение области работы (определяем, где находится imageContainer)
    function _getTransformedRect() {
        //преобразуем точку 0,0 в системе координат imageContainer к целевой системе координат mainRoot
        var topLeft = imageContainer.mapToItem(mainRoot, 0, 0)
        var topRight = imageContainer.mapToItem(mainRoot, imageContainer.width, 0)
        var bottomLeft = imageContainer.mapToItem(mainRoot, 0, imageContainer.height)
        var bottomRight = imageContainer.mapToItem(mainRoot, imageContainer.width, imageContainer.height)

        //Находим min/max координат
        var minX = Math.min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x) - 100 //px
        var maxX = Math.max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x) + 100
        var minY = Math.min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y) - 100
        var maxY = Math.max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y) + 100
        // console.log("_getTransformedRect", minX, minY, maxX - minX, maxY - minY)
        return Qt.rect(minX, minY, maxX - minX, maxY - minY)
    }

    //Вычисление расстояния между двумя точками
    function _distance(p1, p2) {
        return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
    }

    //Вычисление центра между двумя точками
    function _centerPoint(p1, p2) {
        return Qt.point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }

    //Функция ограничения позиции при выходе за границы
    property var _memoryPos: Qt.point(0, 0)
    property var _memoryZoomCenter: Qt.point(0, 0)
    function _limitPosition() {
        var pos = imageContainer.mapToItem(mainRoot, 0, 0) //текущая позиция imageContainer левого верхнего угла в координатах mainRoot

        //Размеры трансформированного изображения
        var imgWidth = imageContainer.width * zoomedScale
        var imgHeight = imageContainer.height * zoomedScale
        var paddingX = 300 //минимальный отступ от краев по X

        //Проверяем левую, правую границу
        if (-imgWidth + paddingX <= pos.x && pos.x <= touchArea.width - paddingX) {
            _memoryPos.x = imagePosition.x
            _memoryZoomCenter.x = zoomCenter.x
        }
        //Проверяем верхнюю, нижнюю границу
        if (-imgHeight - 100 <= pos.y && pos.y <= touchArea.height - 500) {
            _memoryPos.y = imagePosition.y
            _memoryZoomCenter.y = zoomCenter.y
        }
        imagePosition = _memoryPos
        zoomCenter = _memoryZoomCenter
    }

    onPressed: (touchPoints) => {    //Срабатывает при первом касании первого пальца, срабатывает второй раз при касании второго пальца, дальше работает onUpdated
                   if (touchPoints.length === 1) {
                       //Начало перемещения
                       _initia = true
                       _initialPosition = imagePosition
                       _newXY = _initialPosition
                       grabPosition = false;

                       //Двойной клик
                       _clickCount++

                       //Проверяем, находятся ли точки касания внутри допустимой области
                       var point = touchPoints[0]
                       var rect = _getTransformedRect()

                       if (point.x < rect.x || point.x > rect.x + rect.width ||
                           point.y < rect.y || point.y > rect.y + rect.height) {
                           //Если точка касания вне области - игнорируем событие
                           _clickCount = 0
                           return
                       }
                   }
                   // console.log("onPressed", _clickCount, _initialPosition.x)
               }

    onTouchUpdated: (touchPoints) => {
                        //Инициализация масштабирования
                        if (_initia && touchPoints.length === 2) {
                            _initialDistance = _distance(touchPoints[0], touchPoints[1])
                            _initialCenter = _centerPoint(touchPoints[0], touchPoints[1])
                            _initia = false
                            //Двойной клик
                            _clickCount = 0
                        }
                        // console.log("onTouchUpdated", touchPoints.length, _onlyMovY, _clickCount)
                    }

    onUpdated: (touchPoints) => {
                   //Проверяем, находятся ли точки касания внутри допустимой области
                   var rect = _getTransformedRect()
                   for (var i = 0; i < touchPoints.length; i++) {
                       var point = touchPoints[i]
                       if (touchPoints.length === 2 && (point.x < rect.x || point.x > rect.x + rect.width ||
                                                        point.y < rect.y || point.y > rect.y + rect.height)) {
                           //Если точка касания вне области - игнорируем событие
                           return
                       }
                   }

                   //Мультитач
                   if (touchPoints.length === 2) {
                       //Обработка масштабирования
                       var currentDistance = _distance(touchPoints[0], touchPoints[1])
                       var scaleFactor = (currentDistance / _initialDistance === 1) ? zoomedScale : speedScale * currentDistance / _initialDistance;
                       var newScale = Math.max(minScale, Math.min(maxScale, scaleFactor))
                       // console.log("touchPoints", _initialDistance,  currentDistance, currentDistance / _initialDistance, newScale)

                       //Обработка перемещения при масштабировании
                       var currentCenter = _centerPoint(touchPoints[0], touchPoints[1])
                       zoomCenter = (currentDistance / _initialDistance === 1) ? zoomCenter : currentCenter

                       //Корректируем позицию изображения при масштабировании
                       _newXY = Qt.point(_initialPosition.x + (currentCenter.x - _initialCenter.x), _initialPosition.y + (currentCenter.y - _initialCenter.y))
                       zoomedScale = newScale //вначале ограничили, затем изменили масштаб
                   }

                   //Обработка перемещения одним пальцем
                   if (touchPoints.length === 1) {
                       if (zoomedScale == defaultScale) {
                           //Перемещение только по оси Y компенсируем с учетом измененного масштаба для данной области
                           _newXY.y = _initialPosition.y + (touchPoints[0].y - touchPoints[0].startY) / zoomedScale
                       }
                       if (zoomedScale > defaultScale) {
                           //Перемещение только по оси Y компенсируем с учетом измененного масштаба для данной области
                           _newXY = Qt.point(_initialPosition.x + (touchPoints[0].x - touchPoints[0].startX), _initialPosition.y + (touchPoints[0].y - touchPoints[0].startY))
                       }
                   }
                   //Вначале обновляем, потом считаем лимиты, иначе, зайдя за границу можно не выйти
                   imagePosition = _newXY
                   _limitPosition();
                   // console.log("onUpdated", touchPoints.length, _newXY.x, _newXY.y)

                   //Флаг смены позиции
                   if (touchPoints.length >= 1) {
                       if (Math.abs(touchPoints[0].x - touchPoints[0].startX) > 10 || Math.abs(touchPoints[0].y - touchPoints[0].startY) > 10 || touchPoints.length >= 2) {
                           grabPosition = true;
                       }
                   }
               }

    onReleased: {
        //Двойной клик
        if (_clickCount === 1) {
            clickTimer.start()
        } else if (_clickCount === 2) {
            clickTimer.stop()
            _handleDoubleClick()
        }
        grabPosition = true; //true - меняем флаг для сброса таймеров при отпускании, когда управление переданного данному блоку (если у детей есть таймеры длительности нажатия)
        // console.log("onReleased", _initialPosition.x)
    }
}
