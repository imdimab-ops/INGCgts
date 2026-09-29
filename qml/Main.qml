import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import InsetsHelper 1.0
import "./components"

ApplicationWindow {
    id: mainWindow
    visible: true
    title: qsTr("INGCgts")

    //Оптимизация под мобильные экраны (без нее на OnePlus складывается размер header + insetsApp.getStatusBarHeight())
    //на Samsung отображается корректно
    flags: Qt.MaximizeUsingFullscreenGeometryHint
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    // Устанавливаем голубой градиентный фон от центра к краям
    // color: "transparent" // делаем окно прозрачным, чтобы был виден градиент

    // Добавляем прямоугольник с градиентом, который заполнит всё окно
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#fffaf4" }  //почти белый с кремовым оттенком
            GradientStop { position: 0.5; color: "#f8f0e6" }  //светлый кремовый
            GradientStop { position: 1.0; color: "#f0e2d0" }  //теплый кремовый
        }
    }

    property bool _clientConn: false
    property bool _serverConnOPC: false
    Connections {
        target: appEng
        function onFcliUpdate (arg) {
            _clientConn = arg.conn
            _updateIcon(_clientConn, _serverConnOPC)
            timer.restart()
        }
    }
    Connections {
        target: appEng
        function onFsrvUpdate (arg) {
            _serverConnOPC = arg.opcconn
            _updateIcon(_clientConn, _serverConnOPC)
            timer.restart()
        }
    }
    Connections {
        target: appEng
        function onFdataUpdate (arg) {
            var newText = arg.MODE_DESCR.pv
            if (modeDescription.text !== newText) {
                modeDescription.text = newText
                //изменяем размер шрифта в зависимости от длины текста
                if (newText.length > 40) {
                    modeDescription.font.pixelSize = 12
                } else if (newText.length > 25) {
                    modeDescription.font.pixelSize = 14
                } else {
                    modeDescription.font.pixelSize = 16
                }
            }
            var newCount = Number(arg.COUNTDOWN.pv) & 0xFFFF //привели к uint16 (0..65535)
            if (count.text !== newCount) {
                count.text = newCount
            }
        }
    }
    Timer {
        id: timer
        interval: 2000
        onTriggered: {
            console.log("timer Triggered")
            _updateIcon(false, false)
        }
    }
    function _updateIcon(cli, srv) {
        stwConnectOPC.source = (cli && srv) ? "/img/icon/success.svg" : "/img/icon/successErr.svg"
    }

    Component.onCompleted: {
        InsetsHelper.lockPortrait() // Блокируем экран в портретном положении
        toolBar.topPadding = InsetsHelper.getStatusBarHeight(); // Устанавливаем отступы при повторных загрузках Main.qml
        footerBar.bottomPadding = InsetsHelper.getNavigationBarHeight()
        console.log('getStatusBarHeight', InsetsHelper.getStatusBarHeight(), "getNavigationBarHeight", InsetsHelper.getNavigationBarHeight())
    }

    header: ToolBar {
        id: toolBar
        topPadding: InsetsHelper.getStatusBarHeight()  // Определяем отступы сверху и снизу (StatusBar, NavigationBar)

        // Прозрачность и удаление стандартного фона
        background: Rectangle {
            color: "#80696969" // Тёмно-серый (50% прозрачности)
        }

        RowLayout {
            spacing: 2
            anchors {
                fill: parent
                verticalCenter: parent.verticalCenter
                margins: 0  // Можно добавить отступы со всех сторон, если нужно
            }
            ToolButton {
                icon.source: "/img/icon/menu.svg"
                Layout.alignment: Qt.AlignLeft  // Выравнивание по вертикали
                onClicked: menu.open()
                onPressedChanged: scale = pressed ? 0.8 : 1.0
                Behavior on scale {NumberAnimation { duration: 100 }}
            }
            Image {
                id: stwConnectOPC
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: "/img/icon/successErr.svg"
                Layout.preferredHeight: parent.height * 0.5   // ← ограничиваем по высоте
                Layout.preferredWidth:  Layout.preferredHeight
                Layout.alignment: Qt.AlignVCenter
                sourceSize.height: height
                sourceSize.width:  width
            }
            Label {
                id: modeDescription
                text: qsTr("INGC GTS")
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter  // Выравнивание по вертикали
                elide: Text.ElideRight        // ← если не влезает — многоточие, а не наложение
            }
            Label {
                id: count
                text: qsTr("count")
                font.pixelSize: 12
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight  // Выравнивание по вертикали
            }
            //спейсер справа
            // Item {
            //     Layout.preferredWidth: stwConnectOPC.Layout.preferredWidth
            // }
            ToolButton {
                icon.source: "/img/icon/settings.svg"
                Layout.alignment: Qt.AlignRight  // Выравнивание по вертикали
                onClicked: settingsMenu.open()
                onPressedChanged: scale = pressed ? 0.8 : 1.0
                Behavior on scale {NumberAnimation { duration: 100 }}
            }
        }
    }

    Menu {
        id: menu
        title: qsTr("Menu")
        x: 0
        MenuItem {
            id: menuHome
            text: qsTr("&Home")
            icon.source: "/img/icon/home.svg"
            onClicked: stackLayout.currentIndex = 0
        }
        MenuItem {
            id: menuGtu
            text: qsTr("&GTU")
            icon.source: "/img/icon/turbine.svg"
            onClicked: stackLayout.currentIndex = 1
        }
        MenuItem {
            id: menuChart
            text: qsTr("&График")
            icon.source: "/img/icon/chart.svg"
            onClicked: stackLayout.currentIndex = 2
        }
        MenuItem {
            id: menuMessage
            text: qsTr("&Журнал")
            icon.source: "/img/icon/messagelog.svg"
            onClicked: stackLayout.currentIndex = 3
        }
    }

    Menu {
        id: settingsMenu
        title: qsTr("Settings")
        x: parent.width - width
        MenuItem {
            text: qsTr('&Connect')
            onClicked: {
                loader.source = ""
                loader.source = "ConnDialog.qml"
            }
        }
        MenuItem {
            text: qsTr('&SystemLog')
            onClicked: systemLog.open()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("About")
            onClicked: {
                // Создаем диалог динамически
                var dialog = Qt.createComponent("About.qml").createObject(this, {});
                dialog.closed.connect(function() { dialog.destroy() })
                dialog.open();
            }
        }
    }
    SystemLog {
        id: systemLog
        visible: false
    }
    Loader {
        id: loader
        asynchronous: true
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 50  // Отступ от верха
        }
        onLoaded: if(item) item.open()
    }

    //подсвечиваем элементы меню активной страницы (свойство highlighted работает под Android, под Win не работает)
    function fn_menu(index) {
        menuHome.highlighted = (index === 0) ? true : false
        menuGtu.highlighted = (index === 1) ? true : false
        menuChart.highlighted = (index === 2) ? true : false
        menuMessage.highlighted = (index === 3) ? true : false
        messageBar.visible = (index !== 3)   // Cкрываем messageBar, когда открыт messagelog
        console.log("currenIndex " + index)

        if (index === 2 || index === 3) {
            InsetsHelper.unlockOrientation()
        } else {
            InsetsHelper.lockPortrait()
        }
    }
    // Коннект для отслеживания изменения положения экрана
    Connections {
        target: Screen
        function onOrientationChanged() { mainWindow.orientationChanged() }
    }
    // Блокируем кнопку назад
    Shortcut {
        sequence: "Back" // Последовательность для Android "Назад"
        onActivated: {
            mainWindow.orientationChanged()
            console.log("Back button intercepted");
        }
    }
    function orientationChanged() {
        if (Screen.orientation === Qt.LandscapeOrientation || Screen.orientation === Qt.InvertedLandscapeOrientation) {
            toolBar.visible = false
            footerBar.visible = false
            if (stackLayout.currentIndex !== 3) messageBar.visible = false
            InsetsHelper.setImmersiveMode(true)
        } else {
            toolBar.visible = true
            footerBar.visible = true
            if (stackLayout.currentIndex !== 3) messageBar.visible = true
            InsetsHelper.setImmersiveMode(false)
        }
        console.log("Screen.orientation:", Screen.orientation);
    }

    //Информационное сообщение о выходе новой версии
    MessagePopup {}

    MessageBar {
        id: messageBar
        height: visible ? implicitHeight : 0    //Обнуляем высоту при скрытии
        anchors {
            top: parent.top
            topMargin: 0
            left: parent.left
            right: parent.right
        }
    }

    StackLayout {
        id: stackLayout
        currentIndex: 1 //Загружаем вкладку GTU
        anchors {
            top: parent.top
            topMargin: messageBar.visible ? messageBar.heightDefault : 0
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        onCurrentIndexChanged: fn_menu(currentIndex)

        Item {
            opacity: StackLayout.isCurrentItem ? 1 : 0.5
            scale: StackLayout.isCurrentItem ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300 } }
            Loader {
                id: homeLoader
                anchors.fill: parent
                asynchronous: true
                source: "Home.qml"
                //доступ к свойствам
                onLoaded: {}
            }
            Connections {
                target: homeLoader.item
                enabled: homeLoader.status === Loader.Ready && chartLoader.status === Loader.Ready
                ignoreUnknownSignals: true
            }
        }

        Item {
            opacity: StackLayout.isCurrentItem ? 1 : 0.5
            scale: StackLayout.isCurrentItem ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300 } }
            Loader {
                id: gtuLoader
                anchors.fill: parent
                asynchronous: true
                source: "GTU.qml"
                //доступ к свойствам
                onLoaded: {}
            }
            Connections {
                target: gtuLoader.item
                enabled: gtuLoader.status === Loader.Ready && chartLoader.status === Loader.Ready
                ignoreUnknownSignals: true
            }
        }
        Item {
            opacity: StackLayout.isCurrentItem ? 1 : 0.5
            scale: StackLayout.isCurrentItem ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300 } }
            Loader {
                id: chartLoader
                anchors.fill: parent
                asynchronous: true
                source: "Chart.qml"
                //доступ к свойствам
                onLoaded: {}
            }
        }
        Item {
            opacity: StackLayout.isCurrentItem ? 1 : 0.5
            scale: StackLayout.isCurrentItem ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300 } }
            Loader {
                anchors.fill: parent
                asynchronous: true
                source: "MessageLog.qml"
            }
        }
        Item {
            opacity: StackLayout.isCurrentItem ? 1 : 0.5
            scale: StackLayout.isCurrentItem ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300 } }
            ScrollView {
                width: 200
                height: 200

                Label {
                    text: "ABC"
                    font.pixelSize: 224
                }
            }
        }
    }

    // PageIndicator {
    //     id: pageIndicator
    //     count: stackLayout.count
    //     currentIndex: stackLayout.currentIndex
    //     anchors {
    //         bottom: stackLayout.bottom
    //         horizontalCenter: parent.horizontalCenter
    //     }
    // }

    footer: ToolBar {
        id: footerBar
        bottomPadding: InsetsHelper.getNavigationBarHeight()   // Определяем отступы сверху и сниху (StatusBar, NavigationBar)

        // Прозрачность и удаление стандартного фона
        background: Rectangle {
            color: "#80696969" // Тёмно-серый (50% прозрачности)
        }

        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                margins: 0  // Можно добавить отступы со всех сторон, если нужно
            }
            spacing: 20

            ToolButton {
                icon.source: "/img/icon/home.svg"
                onClicked: stackLayout.currentIndex = 0
                onPressedChanged: scale = pressed ? 0.8 : 1.0
                Behavior on scale {NumberAnimation { duration: 100 }}
            }
            ToolButton {
                icon.source: "/img/icon/turbine.svg"
                onClicked: stackLayout.currentIndex = 1
                onPressedChanged: scale = pressed ? 0.8 : 1.0
                Behavior on scale {NumberAnimation { duration: 100 }}
            }
            ToolButton {
                icon.source: "/img/icon/chart.svg"
                onClicked: stackLayout.currentIndex = 2
                onPressedChanged: scale = pressed ? 0.8 : 1.0
                Behavior on scale {NumberAnimation { duration: 100 }}
            }
        }
    }
}
