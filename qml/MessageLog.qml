import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property int _maxVisible: 500

    //Автоматически вычисляемые ширины
    property int _colIdWidth: 20
    property int _colTimeWidth: 40
    property int _colSourceWidth: 100
    property int _colMessageWidth: 300

    //Вычисляемая общая ширина
    property int _totalWidth: _colIdWidth + _colTimeWidth + _colSourceWidth + _colMessageWidth

    //Модель для лога
    ListModel {
        id: logModel
    }

    Connections {
        target: appEng
        function onFdataUpdate(arg) {
            if (!arg || !arg.events) return;

            var newLines = [];
            for (var i = 0; i < arg.events.length; i++) {
                newLines.push(arg.events[i]);
            }

            //добавляем в буфер таймера
            appendTimer.pendingLines = appendTimer.pendingLines.concat(newLines);
            appendTimer.restart();
        }
    }

    //троттлинг обновления
    Timer {
        id: appendTimer
        interval: 60
        repeat: false
        property var pendingLines: []

        onTriggered: {
            if (pendingLines.length === 0) return;
            var linesToAdd = pendingLines.slice(-_maxVisible);
            pendingLines = [] //очищаем буфер

            //Удаляем лишние старые строки
            while (logModel.count + linesToAdd.length > _maxVisible) {
                logModel.remove(logModel.count - 1, 1);
            }

            //Обновляем максимальные ширины на основе добавляемых строк
            for (var i = 0; i < linesToAdd.length; i++) {
                var logEntry = linesToAdd[i];

                var idText = logEntry.id || "";
                var timeText = Qt.formatDateTime(logEntry.time, "dd.MM.yyyy hh:mm:ss.zzz");
                var sourceText = logEntry.sourceName || "";
                var messageText = logEntry.message || "";

                //Обновляем максимальные ширины
                _colIdWidth = Math.max(_colIdWidth, _measureText(idText) + 5);
                _colTimeWidth = Math.max(_colTimeWidth, _measureText(timeText, 9, true) + 2);
                _colMessageWidth = Math.max(_colMessageWidth, _measureText(messageText, 9, true) + 0);
                _colSourceWidth = Math.max(_colSourceWidth, _measureText(sourceText) + 2);

                //Добавляем в модель (в начало)
                logModel.insert(0, {
                                    id: idText,
                                    time: timeText,
                                    sourceName: sourceText,
                                    message: messageText,
                                    color: _getLineColor(messageText)
                                });
            }
            //Обновляем общую ширину
            _totalWidth = _colIdWidth + _colTimeWidth + _colSourceWidth + _colMessageWidth;
        }
    }

    //Компонент и ф-я для измерения текста
    Component {
        id: textMeasurerComponent
        Text {
            font.pixelSize: 9
            visible: false
        }
    }
    function _measureText(text, fontSize, isBold) {
        if (!text) return 0;
        var tempText = textMeasurerComponent.createObject(root, {
                                                              "text": text,
                                                              "font.pixelSize": fontSize || 9,
                                                              "font.bold": isBold || false
                                                          });
        var width = tempText.implicitWidth;
        tempText.destroy();
        return width;
    }

    function _getLineColor(text) {
        if (!text) return "white";
        if (text.includes("[Error]")) return "#ffcdd2";
        if (text.includes("[Warning]")) return "#ffe0b2";
        if (text.includes("[Info]")) return "#bbdefb";
        if (text.includes("[Success]")) return "#c8e6c9";
        if (text.includes("[User]")) return "#f5f5f5";
        return "white";
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        //Явно указываем ширину содержимого для горизонтальной прокрутки
        contentWidth: _totalWidth

        //Полосы прокрутки (опционально)
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        //Колонка с содержимым
        Column {
            id: logColumn
            width: _totalWidth
            spacing: 1

            //========== ЗАГОЛОВОК ==========
            Rectangle {
                width: _totalWidth
                height: 20
                color: "#f0f0f0"
                z: 2

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: 0

                    //Колонка ID
                    Rectangle {
                        width: _colIdWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.fill: parent
                            text: "ID"
                            font.bold: true
                            padding: 2
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    //Колонка Время
                    Rectangle {
                        width: _colTimeWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.fill: parent
                            text: "Время"
                            font.bold: true
                            padding: 2
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    //Колонка Сообщение
                    Rectangle {
                        width: _colMessageWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.fill: parent
                            text: "Сообщение"
                            font.bold: true
                            padding: 2
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    //Колонка Источник
                    Rectangle {
                        width: _colSourceWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.fill: parent
                            text: "Источник"
                            font.bold: true
                            padding: 2
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                //Разделительная линия
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#ccc"
                }
            }

            //========== СПИСОК СТРОК ЛОГА ==========
            Repeater {
                id: logRepeater
                model: logModel

                //Делегат для каждой строки лога
                Rectangle {
                    width: _totalWidth
                    height: 17
                    color: model.color

                    Row {
                        width: parent.width
                        height: parent.height
                        spacing: 0

                        // Ячейка ID
                        Rectangle {
                            width: _colIdWidth
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.fill: parent
                                text: model.id || ""
                                padding: 2
                                font.pixelSize: 9
                                color: "#555"
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        //Ячейка Время
                        Rectangle {
                            width: _colTimeWidth
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.fill: parent
                                text: model.time || ""
                                padding: 2
                                font.pixelSize: 9
                                color: "#555"
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        //Ячейка Сообщение
                        Rectangle {
                            width: _colMessageWidth
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.fill: parent
                                text: model.message || ""
                                padding: 2
                                font.pixelSize: 9
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        //Ячейка Источник
                        Rectangle {
                            width: _colSourceWidth
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.fill: parent
                                text: model.sourceName || ""
                                padding: 2
                                font.pixelSize: 9
                                color: "#555"
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    //Разделительная линия между строками
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Qt.rgba(0, 0, 0, 0.05)
                    }
                }
            }
        }
    }
}
