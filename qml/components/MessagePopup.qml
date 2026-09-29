import QtQuick 2.15
import QtQuick.Controls 6.2
import QtQuick.Layouts
import InsetsHelper 1.0

Item {
    id: root
    x: parent ? (parent.width - width) / 2 : 0  // Центрирование по горизонтали (проверка есть ли родитель)
    y: 100
    width: dialog.width  //Задаем ширину, высоту, иначе размер родительского Item =0 и не работает позиционие элемента
    // height: dialog.height

    Component.onCompleted: {
        // dialog.open()
        // console.log("onCompleted", width, implicitWidth, dialog.implicitWidth)
    }

    Connections {
        target: appEng
        function onFcliUpdate (arg) {
            // rbStart.checked = arg.conn
        }
    }

    Dialog {
        id: dialog
        title: qsTr("Info")
        width: 250 //задаем ширину иначе размер родительского Item =0 и не работает позиционие элемента
        padding: 10
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose  // Запрет автоматического закрытия
        onClosed: destroy() //Автоматическое удаление при закрытии:

        footer: DialogButtonBox {
            standardButtons: Dialog.Ok
            onAccepted: { console.log("Диалог принят") }
            onRejected: { }
        }

        contentItem: GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 5

            //1 строка
            Label {
                text: qsTr("Требуется обновить приложение")
                Layout.alignment: Qt.AlignHCenter
                Layout.columnSpan: 2  //Занимает 2 столбца
            }
            //2 строка
            Label {
                text: qsTr("Current ver:")
                Layout.alignment: Qt.AlignLeft
            }
            Label {
                text: qsTr(InsetsHelper.appVersion)
                Layout.alignment: Qt.AlignLeft
            }
            //3 строка
            Label {
                text: qsTr("Available ver:")
                Layout.alignment: Qt.AlignLeft
            }
            Label {
                text: qsTr("InsetsHelper.appVersion")
                Layout.alignment: Qt.AlignLeft
            }
        }
    }
}
