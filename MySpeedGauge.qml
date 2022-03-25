import QtQuick
import Qt5Compat.GraphicalEffects // required for Glow effect

Item {

    id: speedGauge
    objectName: "speedGauge"

    // Dimensions of the largest asset
    width: 500
    height: 500

    // Variables needed for calculations
    // 1.Values on the texture
    property int minSpeedScaleValue: 0
    property int maxSpeedScaleValue: 180
    // 2. The original 0 needle position on the speed scale
    // requires a -45 degrees rotation of the asset
    // 3. the range of needle movement is 270 degrees in total
    property int minNeedleRotationAngle: -45
    property int maxNeedleRotationAngle: 225

    // Currently unsupported - please don't change
    property bool metricSystem: true


    property int m_speedValue: 0

    function setSpeedValue(newSpeedValue: int){

        if (newSpeedValue !== m_speedValue)
        {
            //console.log("setSpeedValue to ", newSpeedValue);
            speedGauge.m_speedValue = newSpeedValue;
            speedGauge.updateSpeedometer();
        }
    }

    function speedValuetoAngle(currentSpeedValue: int) : real {
        //console.log("speedValuetoAngle(",currentSpeedValue,")");
        //(currentSpeedValue-0)*(225-(-45))/(180-0)-45;
        return ((currentSpeedValue-speedGauge.minSpeedScaleValue)*(speedGauge.maxNeedleRotationAngle-
                    (speedGauge.minNeedleRotationAngle))/(speedGauge.maxSpeedScaleValue-
                    speedGauge.minSpeedScaleValue)+speedGauge.minNeedleRotationAngle);
    }

    function speedValue() : int {
        return speedGauge.m_speedValue
    }

    function updateSpeedometer()
    {
        // The needle is not supposed to come out beyond the max value on the scale,
        // but the text itself turns red in this case
        speedText.text = speedGauge.m_speedValue;
        if(speedGauge.m_speedValue <= speedGauge.maxSpeedScaleValue)
        {
            if(speedText.color != "#D4D8D8")
            {
                speedText.color = "#D4D8D8"
            }
            //needle.rotation= (speedGauge.m_speedValue-0)*(225-(-45))/(180-0)-45;
            needle.rotation = speedValuetoAngle(speedGauge.m_speedValue);
        }
        else
        {
            if(speedText.color != "#dc143c")
            {
                speedText.color = "#dc143c"
            }
            //needle.rotation= (180-0)*(225-(-45))/(180-0)-45;
            needle.rotation= speedValuetoAngle(speedGauge.maxSpeedScaleValue);
        }
        //console.log("needle.rotation = ",needle.rotation);
        needle.rotationChanged();
    }

    Image {
        id: speedGaugeBackground
        width: 500
        height: 500
        anchors.rightMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        source: Qt.resolvedUrl("qrc:/assets/svgFull_Texture_BG.png")


        Image {
            id: speedGaugeScale
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("qrc:/assets/Speed texture.png")

        }

        Canvas {
            id: needleMovementArea
            property bool anticlockwise: false
            property int start_angle: 120
            property int angle_limit: 360
            property int radius: Math.min(innerCircle.height+14,innerCircle.width+14) //(228, 228)
            property int lineWidth: 120

            Image {
                id: needle
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: 452
                height: 452
                rotation: speedGauge.minNeedleRotationAngle
                source: Qt.resolvedUrl("qrc:/assets/Needle.png")
                onRotationChanged: {needleMovementArea.angle = needle.rotation-speedGauge.minNeedleRotationAngle; needleMovementArea.requestPaint()}
            }

            width: parent.width
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            property real angle: 0
            property real nextAngle: (Math.PI/180)*angle

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var needleMovementAreaGradient = ctx.createRadialGradient((width / 2),(height / 2), 0, (width / 2),(height / 2),height);
                needleMovementAreaGradient.addColorStop(0.0, "#2C4F56");
                needleMovementAreaGradient.addColorStop(0.5, "transparent");

                //gradient2.addColorStop(0.0, "#9FBF88"); // 1
                //gradient2.addColorStop(0.10, "#B3CDA1"); // 2
                //gradient2.addColorStop(0.01, "#CDDEC1"); // 3
                //gradient2.addColorStop(0.5, "#E8F0E2"); // 4
                //gradient2.addColorStop(0.5, "#6C8A8A"); // OK1
                //gradient2.addColorStop(0.5, "#46666A"); // OK2

                ctx.beginPath();
                ctx.arc(width/2, height/2, needleMovementArea.radius- (needleMovementArea.lineWidth / 2), (Math.PI/180) * needleMovementArea.start_angle,(Math.PI/180) * needleMovementArea.start_angle + nextAngle, needleMovementArea.anticlockwise);
                ctx.lineWidth = needleMovementArea.lineWidth
                ctx.strokeStyle = needleMovementAreaGradient
                ctx.stroke()
            }
        }

        /*
        ShaderEffect {
            anchors.fill: needleMovementArea
            property var pattern: Image {
                source: Qt.resolvedUrl("images/dial_pattern.png")
            }
            property var fill: Image {
                source: Qt.resolvedUrl(needleMovementArea.fillImage)
            }
            property real value: speedGauge.m_speedValue
            property real circleRadius: needleMovementArea.circleRadius
            //fragmentShader: "qrc:/shader/needleShader.frag.qsb"
            fragmentShader: "qrc:/shader/needleShader.frag.qsb"
        }
        */


        // Qt6 shader code not working, dunno why :(
        /*
        #version 440

        #define M_PI 3.141592653589793
        //#define INNER " + root.circleRadius + "

        layout(location = 0) in vec2 texCoord;
        layout(location = 0) out vec4 fragColor;

        layout(std140, binding = 0) uniform buf {
            float qt_Opacity;
            float value;
            float circleRadius;
        } ubuf;


        layout(binding = 1) uniform sampler2D pattern;
        layout(binding = 2) uniform sampler2D fill;

        void main() {
            vec4 pattern = texture(pattern, texCoord);
            vec4 fill = texture(fill, texCoord);

            vec2 pos = vec2(texCoord.x - 0.5, 0.501 - texCoord.y);
            float d = length(pos);
            float angle = atan(pos.x, pos.y) / (2.0 * M_PI);
            float v = 0.66 * ubuf.value - 0.33;

            // Flare pattern
            vec4 color = mix(pattern, vec4(0.0), smoothstep(v, v + 0.1, angle));
            // Gradient fill color
            color += mix(fill, vec4(0.0), step(v, angle));
            // Punch out the center hole
            color = mix(vec4(0.0), color, smoothstep(ubuf.circleRadius - 0.001, ubuf.circleRadius + 0.001, d));
            // Fade out below 0
            fragColor = mix(color, vec4(0.0), smoothstep(-0.35, -0.5, angle));
        }
        */

        Image {
            id: rim
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("qrc:/assets/BGC_Rim.png")
        }

        Canvas {

            // this canvas creates a gradient (semi-shadow) of the
            // inner circle because the asset file seems to be clipped
            // a bit too much (visually poor), so it has an OpacityMask
            // applied to it

            id: innerCircleGradient
            width: parent.width
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            property int lineWidth: 120

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var semishadow = ctx.createRadialGradient((width/2),(height/2),0,(width/2),(height/2),height);
                semishadow.addColorStop(0.2,"#031B25");
                semishadow.addColorStop(0.25,"transparent");
                ctx.beginPath();
                ctx.arc(width/2,height/2,(Math.min(innerCircle.width,innerCircle.height))-(innerCircleGradient.lineWidth/2),0,360);
                ctx.lineWidth = innerCircleGradient.lineWidth
                ctx.strokeStyle = semishadow
                ctx.stroke()
            }
        }

        Image {
            id: innerCircle
            width: 214
            height: 214
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 0
            anchors.verticalCenterOffset: 0
            source: Qt.resolvedUrl("qrc:/assets/TopCircle.png")

            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
            layer.effect: OpacityMask {
            maskSource: mask
            }

            Rectangle {
                id: mask
                width: innerCircle.width
                height: innerCircle.height
                radius: innerCircle.width/2
                visible: false
            }

            Text {
                id: speedText

                anchors.verticalCenter: innerCircle.verticalCenter
                anchors.horizontalCenter: innerCircle.horizontalCenter
                font.family: "Roboto Medium" // serif font
                font.pixelSize: 60
                font.letterSpacing: 2
                color: "#D4D8D8"
                text: speedGauge.m_speedValue
                antialiasing: true
            }

            Glow {
                anchors.fill: speedText
                radius: 1
                color: "black"
                spread: 0.3
                source: speedText
            }

            Text {
                id: kmh
                anchors.top: speedText.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: innerCircle.horizontalCenter
                font.family: "Roboto Medium" // serif font
                font.pixelSize: 20
                color: "#C2C8C9"
                text: speedGauge.metricSystem ? "km/h" : "mph"
                antialiasing: true
            }

            Glow {
                anchors.fill: kmh
                radius: 1
                //samples: 17
                color: "black"
                spread: 0.3
                source: kmh
            }
        }
    }
}
