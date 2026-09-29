import QtQuick 2.15
import QtQuick.Controls 6.2

//MultiTouchRect.qml - обработка зума только той области, где расположено изображение, перемещения по всей области экрана

// MultiPointTouchArea для обработки мультитач-жестов
MultiPointTouchArea {
    id: touchArea
    anchors.fill: parent
    minimumTouchPoints: 1
    maximumTouchPoints: 2
    mouseEnabled: true //для обработки мыши в десктопном режиме

    //public
    property real maxScale: 1.8
    property real minScale: 0.5
    property real defaultScale: 0.3                 //нормальный масштаб для отображения (по умолчанию)
    property real zoomedScale: 1.0                  //текущий масштаб
    property real zoomedScaleDoubleClick: 1.0       //изменение масштаба при двойном клике
    property real speedScale: 1.0                   //скорость изменения масштаба
    property point imagePosition: Qt.point(0, 0)    //позиция изображения в абсолютных координатах
    property point zoomCenter: Qt.point(0, 0)       //центр координат, относительно которого зумируем
    property var imageContainer //"указатель" на контейнер с изображением, который трансформируем
    property var mainRoot       //"указатель" на область в которой находится imageContainer

    //private
    property real _initialDistance: 0
    property point _initialCenter: Qt.point(0, 0)
    property point _initialPosition: Qt.point(0, 0)
    property point _newXY: Qt.point(0, 0)

    property bool _initia: false    //инициализируем мультитач жесты
    property bool _isScaled: false
    property bool _movY: false      //разрешаем перемещение только по оси Y
    property int _clickCount: 0

    Component.onCompleted: {
        zoomedScale = defaultScale
    }

    // Одиночный клик
    Timer {
        id: clickTimer
        interval: 300 // Интервал для двойного клика (мс)
        onTriggered: {
            parent._clickCount = 0
            console.log("Одиночный клик")
        }
    }

    // Двойной клик
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
        console.log("Двойной клик!")
    }

    // Ограничение области работы
    function _getTransformedRect() {
        // Получаем координаты углов imageContainer в системе координат root
        var topLeft = imageContainer.mapToItem(mainRoot, 0, 0)
        var topRight = imageContainer.mapToItem(mainRoot, imageContainer.width, 0)
        var bottomLeft = imageContainer.mapToItem(mainRoot, 0, imageContainer.height)
        var bottomRight = imageContainer.mapToItem(mainRoot, imageContainer.width, imageContainer.height)

        // Находим min/max координат
        var minX = Math.min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x) - 100 //px
        var maxX = Math.max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x) + 100
        var minY = Math.min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y) - 100
        var maxY = Math.max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y) + 100
        // console.log("_getTransformedRect", minX, minY, maxX - minX, maxY - minY)
        return Qt.rect(minX, minY, maxX - minX, maxY - minY)
    }

    // Вычисление расстояния между двумя точками
    function _distance(p1, p2) {
        return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
    }

    // Вычисление центра между двумя точками
    function _centerPoint(p1, p2) {
        return Qt.point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }

    // Ограничение областей перемещения
    function _limitAreas(X, Y, Scale) {
        // Ограничение области перемещения
        var minX = -imageContainer.width * zoomedScale + 50     //px
        var maxX = touchArea.width - 50

        var minY = -imageContainer.height * zoomedScale - 35    // Перемещаем за область видимости
        var maxY = touchArea.height - 100
        // Преобразуем координаты imageContainer в координаты относительно mainRoot (для расчета в координатах mainRoot)
        var pos = imageContainer.mapToItem(mainRoot, 0, 0)

        if (pos.x < minX) {
            imagePosition.x = Math.max(X, imagePosition.x); //ограничили влево
        } else if (pos.x > maxX) {
            imagePosition.x = Math.min(X, imagePosition.x); //ограничили вправо
        } else {
            imagePosition.x = X                             //рабочая зона
        }
        if (pos.y < minY) {
            imagePosition.y = Math.max(Y, imagePosition.y);
        } else if (pos.y > maxY) {
            imagePosition.y = Math.min(Y, imagePosition.y);
        } else {
            imagePosition.y = Y;
        }
        zoomedScale = Scale
    }

    onPressed: (touchPoints) => {    // Срабатывает при первом касании первого пальца, срабатывает второй раз при касании второго пальца, дальше работает onUpdated
                   if (touchPoints.length === 1) {
                       // Начало перемещения
                       _initia = true
                       _initialPosition = imagePosition
                       _newXY = _initialPosition

                       // Двойной клик
                       _clickCount++

                       // Проверяем, находятся ли точки касания внутри допустимой области
                       var point = touchPoints[0]
                       var rect = _getTransformedRect()
                       _movY = (point.y < rect.y || point.y > rect.y + rect.height) //вышли за пределы области масштабирования, перемещаем только по оси Y

                       if (point.x < rect.x || point.x > rect.x + rect.width ||
                           point.y < rect.y || point.y > rect.y + rect.height) {
                           // Если точка касания вне области - игнорируем событие
                           _clickCount = 0
                           return
                       }
                   }
                   console.log("onPressed", _clickCount, _initialPosition.x)
               }

    onTouchUpdated: (touchPoints) => {
                        // Инициализация масштабирования
                        if (_initia && touchPoints.length === 2) {
                            _initialDistance = _distance(touchPoints[0], touchPoints[1])
                            _initialCenter = _centerPoint(touchPoints[0], touchPoints[1])
                            _isScaled = true
                            _initia = false
                            _movY = false
                            // Двойной клик
                            _clickCount = 0
                        }
                        if (touchPoints.length === 0) {
                            _isScaled = false
                        }
                        console.log("onTouchUpdated", _isScaled, touchPoints.length, _movY, _clickCount)
                    }

    onUpdated: (touchPoints) => {
                   // Проверяем, находятся ли точки касания внутри допустимой области
                   var rect = _getTransformedRect()
                   for (var i = 0; i < touchPoints.length; i++) {
                       var point = touchPoints[i]
                       if (touchPoints.length === 2 && (point.x < rect.x || point.x > rect.x + rect.width ||
                                                        point.y < rect.y || point.y > rect.y + rect.height)) {
                           // Если точка касания вне области - игнорируем событие
                           return
                       }
                   }

                   // Мультитач
                   if (_isScaled && touchPoints.length === 2) {
                       // Обработка масштабирования
                       var currentDistance = _distance(touchPoints[0], touchPoints[1])
                       var newScale = Math.max(minScale, Math.min(maxScale, speedScale * currentDistance / _initialDistance))
                       // console.log("touchPoints", currentDistance / _initialDistance, currentDistance, newScale)

                       // Обработка перемещения при масштабировании
                       var currentCenter = _centerPoint(touchPoints[0], touchPoints[1])
                       zoomCenter = currentCenter

                       // Корректируем позицию изображения при масштабировании
                       _newXY = Qt.point(_initialPosition.x + (currentCenter.x - _initialCenter.x), _initialPosition.y + (currentCenter.y - _initialCenter.y))
                       _limitAreas(_newXY.x, _newXY.y, newScale)
                   }

                   // Обработка перемещения одним пальцем
                   // Если точка касания попадает в область то перемещаем во все стороны (не ограничиваем по оси Y)
                   if (!_isScaled && !_movY && touchPoints.length === 1) {
                       _newXY = Qt.point(_initialPosition.x + (touchPoints[0].x - touchPoints[0].startX), _initialPosition.y + (touchPoints[0].y - touchPoints[0].startY))
                       _limitAreas(_newXY.x, _newXY.y, zoomedScale)
                   }
                   // Если нет, то перемещаем только по оси Y
                   if (!_isScaled && _movY && touchPoints.length === 1) {
                       // Перемещение только по оси Y компенсируем с учетом измененного масштаба для данной области
                       _newXY.y = _initialPosition.y + (touchPoints[0].y - touchPoints[0].startY) / zoomedScale
                       _limitAreas(_newXY.x, _newXY.y, zoomedScale)
                   }
               }

    onReleased: {
        // Двойной клик
        if (_clickCount === 1) {
            clickTimer.start()
        } else if (_clickCount === 2) {
            clickTimer.stop()
            _handleDoubleClick()
        }
        // console.log("onReleased", _isScaled, _initialPosition.x)
    }
}

