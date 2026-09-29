import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import CustomPlot 1.0

Item {

    function updateData (data) {
        //перед формированием запроса выполнять проверку уже добавленных графиков, исключая повторные запросы
        if (data.addTag) customPlot.fsetAddGraph(data.name)
    }
    function _removeWordFromText(text, word) {
        return text.replace(new RegExp(word, 'gi'), ''); // 'gi' = глобально, без учёта регистра
    }

    RowLayout {
        z: 10
        anchors {
            top: parent.top
            right: parent.right
            rightMargin: 10
        }
        spacing: 10

        Label {
            id: labelCount
            text: qsTr("")
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 12
        }

        // Button {
        //     text: "Add"
        //     implicitWidth: 65
        //     implicitHeight: 30
        //     Layout.alignment: Qt.AlignVCenter
        //     leftPadding: 0
        //     rightPadding: 0
        //     opacity: 0.75
        //     font.pixelSize: 10 // Уменьшаем размер шрифта
        //     onClicked: customPlot.fsetAddGraph(0)
        // }

        Button {
            text: "Tags"
            implicitWidth: 65
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            leftPadding: 0
            rightPadding: 0
            opacity: 0.75
            font.pixelSize: 10
            onClicked: dialog.open()
        }

        Item {
            width: 10
        }

        CheckBox {
            id: cbCursor
            text: "Cursor"
            Layout.alignment: Qt.AlignVCenter
            padding: 0
            checked: false
            font.pixelSize: 10
            implicitHeight: 20
            onCheckedChanged: {}
            onClicked: customPlot.fsetCursorLine(checked)
        }

        CheckBox {
            id: cbAScroll
            text: "AScroll"
            Layout.alignment: Qt.AlignVCenter
            padding: 0
            checked: true
            font.pixelSize: 10
            implicitHeight: 20
            onCheckedChanged: customPlot.fsetAutoScroll(checked)
        }
    }

    Dialog {
        id: dialog
        modal: true
        focus: true
        title: qsTr("Tags")
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width, _requiredWidth)
        contentHeight: Math.min(parent.height * 0.7, checkColumn.height) // Ограничиваем максимальную высоту

        property real _requiredWidth: 0

        TextMetrics {
            id: textMetrics
            font.family: "Arial"
            font.pixelSize: 14
        }

        ListModel {
            id: graphsModel
        }
        onOpened: _fillGraphList()

        function _fillGraphList() {
            var _maxWidth = 0
            graphsModel.clear();
            var graphList = customPlot.fgetGraphList();
            for (var i = 0; i < graphList.length; ++i) {
                graphsModel.append({
                                       "name": graphList[i].name,
                                       "color": graphList[i].color,
                                       "checked": graphList[i].checked,
                                   });
                //Измеряем ширину текста
                textMetrics.text = graphList[i].name
                _maxWidth = Math.max(_maxWidth, textMetrics.width)
            }
            _requiredWidth = _maxWidth + 70 + 45 + 10 //Общая требуемая ширина = текст + чекбокс + кнопка + отступы
            // console.log("graphList", graphList)
        }

        ScrollView {
            anchors.fill: parent

            ColumnLayout {
                id: checkColumn
                spacing: 0
                anchors.fill: parent

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#cccccc"
                }

                Repeater {
                    model: graphsModel
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        CheckBox {
                            id: checkBox
                            text: model.name
                            checked: model.checked
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            padding: 0
                            spacing: 5
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: model.color
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: parent.indicator.width + parent.spacing
                            }
                            onCheckedChanged: customPlot.fsetSelectedGraph(text, checked)
                        }

                        ToolButton {
                            id: btnDel
                            text: "Del"
                            enabled: !checkBox.checked
                            padding: 0
                            Layout.alignment: Qt.AlignVCenter //выравнивание элемента
                            onClicked: {
                                customPlot.fsetDeletedGraph(checkBox.text)
                                dialog._fillGraphList()
                            }
                        }
                    }
                }
            }
        }
    }

    CPlot {
        id: customPlot
        anchors.fill: parent
        focus: true
        antialiasing: true
        layer.enabled: true       //аппаратное ускорение
        layer.smooth: false       //отключаем сглаживание
        Component.onCompleted: {
            console.log("customPlot", customPlot)
            fsetInitPlot()
        }
        Component.onDestruction: Qt.plotInstance = null
        onFautoScroll: function(arg) { cbAScroll.checked = arg }
        onFcursorLine: function(arg) { cbCursor.checked = arg }
        onFdataCount: function(arg) { labelCount.text = arg }
    }
}
