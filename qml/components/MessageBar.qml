import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: _dropdownVisible ? 150 : heightDefault
    z: _dropdownVisible ? 10 : 0
    opacity: _dropdownVisible ? 0.95 : 0.5

    property int heightDefault: 50
    property bool _dropdownVisible: false

    ListModel {
        id: logModel
    }

    Behavior on implicitHeight { NumberAnimation { duration: 100 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Connections {
        target: appEng
        function onFcliUpdate(arg) {
            if (!arg.conn) {
                logModel.clear()
                appendTimer.stop()
                appendTimer.pendingLines = []  //Очищаем буфер
            }
        }
    }

    Connections {
        target: appEng
        function onFdataUpdate(arg) {
            var newLines = []
            for (var i = 0; i < arg.events.length; i++) {
                newLines.push(arg.events[i].id + " " + arg.events[i].message)
            }

            //добавляем в буфер таймера
            appendTimer.pendingLines = appendTimer.pendingLines.concat(newLines)
            appendTimer.restart()
        }
    }

    //троттлинг обновления
    Timer {
        id: appendTimer
        interval: 50
        repeat: false
        property var pendingLines: []

        onTriggered: {
            if (pendingLines.length === 0) return
            var linesToAdd = pendingLines.slice(-10)  //Ограничиваем общее количество строк 10
            pendingLines = [] //очищаем буфер

            //Удаляем лишние старые строки
            while (logModel.count + linesToAdd.length > 10) {
                logModel.remove(logModel.count - 1, 1)
            }

            //Добавляем новые строки
            for (var i = 0; i < linesToAdd.length; i++) {
                logModel.insert(0, {
                                    "text": linesToAdd[i],
                                    "color": _getColor(linesToAdd[i])
                                })
            }

            //Прокрутка вверх при новых сообщениях
            if (logModel.count > 0 && listView.visible) {
                listView.positionViewAtIndex(0, ListView.Beginning)
            }
        }
    }

    function _getColor(text) {
        if (text.includes("[Error]")) return "red"
        if (text.includes("[Warning]")) return "orange"
        if (text.includes("[Info]")) return "blue"
        if (text.includes("[Success]")) return "green"
        if (text.includes("[User]")) return "gray"
        return "black"
    }

    Rectangle {
        anchors.fill: parent
        color: _dropdownVisible ? "#f8f0e6" : "transparent"
        border.color: "#cccccc"
        border.width: 1
        radius: 5
    }

    Label {
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: "\u25BC Click \u25BC"
        visible: !_dropdownVisible
        color: "gray"
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 2
        model: logModel
        clip: true

        cacheBuffer: 200
        flickDeceleration: 3000
        maximumFlickVelocity: 5000

        delegate: Item {
            width: listView.width
            height: Math.max(textItem.height + 2, 14)  // Минимальная высота

            Text {
                id: textItem
                width: parent.width
                text: model.text
                color: model.color
                font.family: "Segoe UI Light"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2

                layer.enabled: true
                layer.samplerName: "texture"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true //Позволяем событиям проходить к дочерним элементам
        onClicked: {
            root._dropdownVisible = !root._dropdownVisible
        }
    }
}
