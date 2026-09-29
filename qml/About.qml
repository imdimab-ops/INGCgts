import QtQuick
import QtQuick.Controls 6.2
import InsetsHelper 1.0

Dialog {
    id: dialog
    modal: true
    focus: true
    title: qsTr("About app")

    //Центрируем диалоговое окно по середине
    parent: Overlay.overlay //для модальных окон
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: Math.min(parent.width, parent.height) / 3 * 2
    contentHeight: aboutColumn.height

    property string srvVersion: "none"

    Connections {
        target: appEng
        function onFsrvUpdate (arg) {
            srvVersion = arg.srvVersion
        }
    }

    Column {
        id: aboutColumn
        spacing: 15

        Label {
            width: dialog.availableWidth
            text: qsTr("INGC LLC (Sales and engineering)")
            wrapMode: Label.Wrap
            font.pixelSize: 12
        }

        Label {
            width: dialog.availableWidth
            text: qsTr("14 Nauchny proezd, litera A, bld. 3, Moscow, Russia, 117246, \n"
                       + "E-mai: info@ingc.ru")
            wrapMode: Label.Wrap
            font.pixelSize: 12
        }

        Label {
            width: dialog.availableWidth
            text: qsTr("Ver. " + InsetsHelper.getAppVersion + "\n"
                       +"Ver. " + srvVersion + "\n"
                       + InsetsHelper.getOpenSSLVersionString)
            wrapMode: Label.Wrap
            font.pixelSize: 12
        }
    }
}
