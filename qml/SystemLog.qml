import QtQuick
import QtQuick.Controls 6.2
import QtQuick.Layouts

Dialog {
    id: eventLog
    modal: true
    focus: true
    visible: false
    title: qsTr("SystemLog")
    padding: 0

    //Центрируем диалоговое окно по середине
    parent: Overlay.overlay //для модальных окон
    width: Math.min(parent.width - 10, 800)
    height: Math.min(parent.height - 30, 600)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    Connections {
        target: appEng
        function onFsystemLog (arg) {
            var timestamp = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss.zzz")
            textArea.append(_getColor(timestamp + " " + arg))
        }
    }

    //private
    function _getColor(text) {
        if (text.includes("[Error]")) {
            return '<font color="red">' + text + '</font>'
        } else if (text.includes("[Warning]")) {
            return '<font color="orange">' + text + '</font>'
        } else if (text.includes("[Info]")) {
            return '<font color="blue">' + text + '</font>'
        } else if (text.includes("[Success]")) {
            return '<font color="green">' + text + '</font>'
        } else {
            return text
        }
    }

    ColumnLayout {
        spacing: 0 //Общий отступ между элементами
        anchors.fill: parent
        anchors.margins: 1  //Убираем внешние отступы

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

            //Убираем отступы в ScrollView
            padding: 0
            // contentWidth: availableWidth
            clip: true

            TextArea {
                id: textArea
                width: scrollView.availableWidth
                height: scrollView.availableHeight
                font.family: "Segoe UI Light"
                font.pixelSize: 8
                readOnly: true
                wrapMode: Text.NoWrap //Отключаем перенос для горизонтальной прокрутки
                renderType: Text.NativeRendering //Ускоряет отрисовку
                textFormat: TextEdit.RichText //для поддержки HTML и отображения цвета

                topPadding: 8
                bottomPadding: 8
                leftPadding: 5
                rightPadding: 5

                property int maxLines: 200
                onTextChanged: {
                    const lines = text.split('\n');
                    if (lines.length > maxLines) {
                        text = lines.slice(-maxLines).join('\n'); //Оставляем последние строки maxLines
                    }
                    //Автоматическая прокрутка
                    if (autoScroll.checked) {
                        cursorPosition = text.length  //Перемещаем курсор в конец
                        scrollView.ScrollBar.position = 1.0  //Прокрутка вниз
                        scrollView.ScrollBar.horizontal.position = 0.0
                    }
                }
            }
        }
    }
    footer: RowLayout {
        spacing: 25 //Общий отступ между элементами
        Layout.alignment: Qt.AlignHCenter  //Выравнивание по горизонтали
        Item { Layout.fillWidth: true }
        CheckBox {
            id: autoScroll
            text: "Auto-scroll"
            padding: 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
            checked: autoScroll
        }
        ToolButton {
            text: "Ok"
            padding: 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
            // Layout.rowSpan: 2        // Объединяем 2 строки
            onClicked: eventLog.visible = false
        }
        ToolButton {
            text: "Clear"
            padding: 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
            // Layout.rowSpan: 2        // Объединяем 2 строки
            onClicked: textArea.clear()
        }
        Item { Layout.fillWidth: true }
    }
}
