import QtQuick 2.0
import QtQuick.Controls 6.2
import QtQuick.Window 2.15
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    title: qsTr("INGCgts")

    flags: Qt.MaximizeUsingFullscreenGeometryHint
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    property Component _mainComponent: Qt.createComponent("Main.qml")
    property var _mainWindow: null


    // Фоновое изображение
    AnimatedImage {
        id: backgroundImage
        anchors.centerIn: parent
        source: "qrc:/img/logo_fast.gif" // Укажите путь к вашему изображению
        sourceSize: Qt.size(350, 350)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        playing: true
        opacity: 0.25 // Прозрачность фона (по желанию)
    }

    // Затемнение фона для лучшей читаемости элементов
    Rectangle {
        anchors.fill: parent
        color: "grey"
        opacity: 0.3
    }

    Column {
        anchors.centerIn: parent
        spacing: 10

        Label {
            text: "..."
            font.pixelSize: 26
            font.italic: true
            anchors.horizontalCenter: parent.horizontalCenter  // Выравнивание по центру
        }

        Button {
            text: ">>"
            anchors.horizontalCenter: parent.horizontalCenter  // Выравнивание по центру
            onClicked: _showMainWindow()
        }
    }

    function _createAndOpenMainWindow() {
        if (!_mainWindow && _mainComponent.status === Component.Ready) {
            _mainWindow = _mainComponent.createObject(root);
            if (_mainWindow) {
                _mainWindow.closing.connect(function() {
                    _mainWindow.destroy();
                    _mainWindow = null;
                });
            }
        } else {
            console.error("Error loading Main.qml:", _mainComponent.errorString());
            return;
        }
        if (_mainWindow) {
            _mainWindow.show();
        }
    }
    function _createMainWindow() {
        if (!_mainWindow && _mainComponent.status === Component.Ready) {
            _mainWindow = _mainComponent.createObject(root, {
                                                          visible: false  //Создаем окно скрытым
                                                      });
            if (_mainWindow) {
                _mainWindow.closing.connect(function() {
                    _mainWindow.destroy();
                    _mainWindow = null;
                });
            }
        } else {
            console.error("Error loading Main.qml:", _mainComponent.errorString());
            return;
        }
    }
    function _showMainWindow() {
        if (_mainWindow) _mainWindow.show();
    }

    Timer {
        id: showTimer
        interval: 250
        onTriggered: _showMainWindow()
    }

    Component.onCompleted: {
        /* Порядок: 1.поднимаем коннект, 2.создаем UI, 3.бновляем созданный UI, 4.отображаем через таймер чтобы успело прогрузиться */
        _createMainWindow()
        showTimer.restart()
    }

    Component.onDestruction: {
        if (_mainWindow) {
            _mainWindow.destroy();
        }
    }
}
