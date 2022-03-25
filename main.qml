import QtQuick
import QtQuick.Window
//import qml_cpp_SpeedGaugeBackend 1.0

Window {
    id: iWindow

    width: mySpeedGauge.width
    height: mySpeedGauge.height
    visible: true
    title: qsTr("MySpeedGauge v1.0")
    flags: Qt.FramelessWindowHint | Qt.WA_TranslucentBackground
    color: "#00000000"

    MouseArea {
        anchors.fill: parent
        property real lastMouseX: 0
        property real lastMouseY: 0
        onPressed: {
            lastMouseX = mouseX
            lastMouseY = mouseY
        }
        onMouseXChanged: iWindow.x += (mouseX - lastMouseX)
        onMouseYChanged: iWindow.y += (mouseY - lastMouseY)
    }

    MySpeedGauge {
        id: mySpeedGauge
        objectName: "mySpeedGauge"
    }
}
