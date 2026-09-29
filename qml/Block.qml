import QtQuick
import QtQuick.Controls 6.2
import QtQuick.Layouts
import QtQuick.Window

Item {
      // масштабируем в центре экрана
      // x: - colLayout.width / 2
      // y: - colLayout.height / 2
      anchors.fill: parent // Заполняем родительский элемент

      ScrollView  {
            anchors.fill: parent // Занимает всю область родителя
            clip: true // Обрезать контент за пределами ScrollView
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ScrollBar.vertical.interactive: true
            contentHeight: colLayout.height
            Layout.alignment: Qt.AlignHCenter


            ColumnLayout {
                  id: colLayout
                  width: parent.width // Ширина равна ScrollView
                  spacing: 0

                  Label {
                        text: "loadPage"
                        Layout.alignment: Qt.AlignHCenter
                  }

                  Rectangle {
                        id: rect1
                        Layout.alignment: Qt.AlignHCenter
                        width: 40;
                        height: 40;
                        border.width: 1
                  }
                  Image {
                        id: imgBlock
                        asynchronous: true //загрузка изображения асинхронно
                        // scale: 0.3
                        // Layout.fillWidth: true  //растянуть на всю ширину
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: 250
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/img/block.png"
                        Rectangle {
                              anchors.fill: parent
                              color: "transparent"
                              border.color: "black"
                              border.width: 1
                        }
                  }
                  Image {
                        id: imgBlock1
                        asynchronous: true //загрузка изображения асинхронно
                        // scale: 0.3
                        // Layout.fillWidth: true  //растянуть на всю ширину
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: 250
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/img/block.png"
                        Rectangle {
                              anchors.fill: parent
                              color: "transparent"
                              border.color: "black"
                              border.width: 1
                        }
                  }
                  Image {
                        id: imgBlock2
                        asynchronous: true //загрузка изображения асинхронно
                        // scale: 0.3
                        // Layout.fillWidth: true  //растянуть на всю ширину
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: 250
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/img/block.png"
                        Rectangle {
                              anchors.fill: parent
                              color: "transparent"
                              border.color: "black"
                              border.width: 1
                        }
                  }
                  Image {
                        id: imgBlock3
                        asynchronous: true //загрузка изображения асинхронно
                        // scale: 0.3
                        // Layout.fillWidth: true  //растянуть на всю ширину
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: 250
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/img/block.png"
                        Rectangle {
                              anchors.fill: parent
                              color: "transparent"
                              border.color: "black"
                              border.width: 1
                        }
                  }
            }
      }
}
