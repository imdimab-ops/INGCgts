import QtQuick 2.15
import QtQuick.Controls
// import QtQuick.Controls.Universal  // Для RegExpValidator в Qt 6.9+
import QtQuick.Layouts
import QtQuick.Window 2.15


Dialog {
    title: qsTr("Connect")
    // Позиционирование внутри Loader
    x: parent ? (parent.width - width) / 2 : 0  // Центрирование по горизонтали (проверка есть ли родитель)
    y: 0  // Фиксированное положение вверху Loader

    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose  // Запрет автоматического закрытия
    topPadding: 5
    bottomPadding: 5
    leftPadding: 0
    rightPadding: 0
    onOpened: appEng.fgetConnectSettings()
    onClosed: {}
    onAccepted: appEng.fsetConnectToHost(tfIP.text, tfPort.text, tfLogin.text, tfPass.text);
    onRejected: console.log("Cancel clicked")

    Connections {
        target: appEng
        function onFcliUpdate (arg) {
            statusConnect.source = (arg.conn) ? "qrc:/img/icon/plugconnected.svg" : "qrc:/img/icon/plugdisconnected.svg"
            tfIP.enabled = !arg.conn
            tfPort.enabled = !arg.conn
            tbStart.enabled = !arg.conn
            tbStop.enabled = arg.conn
            tfLogin.enabled = !arg.conn
            tfPass.enabled = !arg.conn
        }
    }
    //две функции в одном коннекте не работают
    Connections {
        target: appEng
        function onfconnectSettings (host, port, login, pass) {
            tfIP.text = host
            tfPort.text = port
            tfLogin.text = login
            tfPass.text = pass

            console.log("onUi_connectSettings", host)
        }
    }

    footer: DialogButtonBox {
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: { console.log("Диалог принят") }
        // onRejected: { getLocalIPs() }
    }

    contentItem: ColumnLayout {
        id: settingsColumn
        spacing: 10

        GridLayout {
            columns: 5
            rowSpacing: 10
            columnSpacing: 10
            Layout.topMargin: 20 //отступ от верхнего элемента внутри родителя (ColumnLayout)

            //1 строка
            Label {
                text: qsTr("IP:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: tfIP
                implicitWidth: 110
                implicitHeight: 30
                text: qsTr("")
                font.pixelSize: height * 0.4  // 50% от высоты поля
                placeholderText: "IP"
                maximumLength: 15  // Максимум 4 цифры
                horizontalAlignment: Text.AlignHCenter  //Выравнивание текста по центру
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
                echoMode: TextInput.Normal // Пароль - TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly //Настройки для мобильных устройств (в Win не работает)
                // Валидатор для проверки полного IP
                validator: RegularExpressionValidator {
                    regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
                }
            }

            Label {
                text: qsTr("Port:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: tfPort
                implicitWidth: 60
                implicitHeight: 30
                text: qsTr("")
                font.pixelSize: height * 0.4  // 50% от высоты поля
                placeholderText: "Port"
                maximumLength: 4  // Максимум 4 цифры
                horizontalAlignment: Text.AlignHCenter  //Выравнивание текста по центру
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter //выравнивание элемента
                echoMode: TextInput.Normal // Пароль - TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly //Настройки для мобильных устройств (в Win не работает)
                validator: RegularExpressionValidator {
                    regularExpression: /^[0-9]*$/  //Только цифры RegularExpressionValidator в Qt 6.9+
                }
            }

            ToolButton {
                text: "Clear"
                padding: 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
                Layout.rowSpan: 2        // Объединяем 2 строки
                onClicked: {
                    tfIP.clear()
                    tfPort.clear()
                    tfIP.focus = true
                    tfLogin.clear()
                    tfPass.clear()
                }
            }

            //2 стока
            Label {
                text: qsTr("Login:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: tfLogin
                implicitWidth: 110
                implicitHeight: 30
                text: qsTr("")
                font.pixelSize: height * 0.4  // 50% от высоты поля
                placeholderText: "Login"
                maximumLength: 15  // Максимум 4 цифры
                horizontalAlignment: Text.AlignHCenter  //Выравнивание текста по центру
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter //выравнивание элемента
                echoMode: TextInput.Normal // Пароль - TextInput.Password
                // inputMethodHints: Qt.ImhDigitsOnly //Настройки для мобильных устройств (в Win не работает)
            }

            Label {
                text: qsTr("Pass:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: tfPass
                implicitWidth: 80
                implicitHeight: 30
                text: qsTr("")
                font.pixelSize: height * 0.4  // 50% от высоты поля
                placeholderText: "Password"
                maximumLength: 15  // Максимум 4 цифры
                horizontalAlignment: Text.AlignHCenter  //Выравнивание текста по центру
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter //выравнивание элемента
                echoMode: TextInput.PasswordEchoOnEdit // Пароль - TextInput.Password
                passwordCharacter: "•"
                // inputMethodHints: Qt.ImhDigitsOnly //Настройки для мобильных устройств (в Win не работает)
            }
        }

        RowLayout {
            spacing: 30 //Общий отступ между элементами
            Layout.alignment: Qt.AlignHCenter  // Выравнивание по горизонтали

            Image {
                id: statusConnect
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(24, 24)
                source: "qrc:/img/icon/plugdisconnected.svg"
            }

            ToolButton  {
                id: tbStart
                text: qsTr("&Connect")
                enabled: true
                background: Rectangle {
                    implicitWidth: 60
                    color: tbStart.down ? "#d6d6d6" : "#f6f6f6"
                    border.color: "#26282a"
                    border.width: 1
                    radius: 2
                }
                onClicked: appEng.fsetConnectToHost(tfIP.text, tfPort.text, tfLogin.text, tfPass.text);
            }
            ToolButton  {
                id: tbStop
                text: qsTr("&Disconn")
                enabled: false
                background: Rectangle {
                    implicitWidth: 60
                    color: tbStop.down ? "#d6d6d6" : "#f6f6f6"
                    border.color: "#26282a"
                    border.width: 1
                    radius: 2
                }
                onClicked: appEng.fsetDisconnectToHost();
            }
        }

        //Горизонтальный разделитель
        Rectangle {
            implicitHeight: 1
            Layout.fillWidth: true
            color: "gray"
            opacity: 0.5
        }
    }
}
