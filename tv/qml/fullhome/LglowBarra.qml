import QtQuick 2.6
import QtGraphicalEffects 1.0

// [fullhome-custom] Botones de arriba de LGlow, grandes para el puntero: el tema (abre el menú
// de tema) y el engranaje (abre el panel rápido de LGlow). Reemplaza a la fila de íconos de LG.
FocusScope {

    id: root

    property int actual: 1              // 0 = tema, 1 = engranaje
    property int lado: styleSheet.getRValue(84)

    signal exitDown()
    signal abrirTema()
    signal abrirAjustes()

    width: fila.width
    height: lado

    function activar(i) {
        if (i === 0)
            root.abrirTema();
        else
            root.abrirAjustes();
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Left:
            if (actual > 0) actual--;
            event.accepted = true;
            break;
        case Qt.Key_Right:
            if (actual < 1) actual++;
            event.accepted = true;
            break;
        case Qt.Key_Down:
            root.exitDown();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.activar(actual);
            event.accepted = true;
            break;
        }
    }

    Row {
        id: fila
        spacing: styleSheet.getRValue(22)

        Repeater {
            model: 2

            delegate: Item {

                id: boton

                property bool sel: (root.activeFocus && root.actual === index) || zona.containsMouse

                width: root.lado
                height: root.lado
                scale: sel ? 1.1 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                RectangularGlow {
                    anchors.fill: parent
                    anchors.topMargin: styleSheet.getRValue(6)
                    glowRadius: styleSheet.getRValue(18)
                    spread: 0.1
                    cornerRadius: width / 2 + glowRadius
                    color: lglowTema.sombra
                }

                Rectangle {
                    id: circulo
                    anchors.fill: parent
                    radius: width / 2
                    color: boton.sel ? lglowTema.texto : lglowTema.pastilla
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                // Tema: un círculo con la mitad rellena
                Item {
                    anchors.centerIn: parent
                    width: Math.round(root.lado * 0.42)
                    height: width
                    visible: index === 0

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: styleSheet.getRValue(4)
                        border.color: boton.sel ? lglowTema.pastilla : lglowTema.icono
                    }

                    Item {
                        width: parent.width / 2
                        height: parent.height
                        clip: true

                        Rectangle {
                            width: parent.height
                            height: parent.height
                            radius: width / 2
                            color: boton.sel ? lglowTema.pastilla : lglowTema.icono
                        }
                    }
                }

                // Engranaje dibujado (el de la fuente de LG no queda centrado)
                Canvas {
                    id: engrane
                    property color tinta: boton.sel ? lglowTema.pastilla : lglowTema.icono
                    anchors.centerIn: parent
                    width: Math.round(root.lado * 0.46)
                    height: width
                    visible: index === 1
                    onTintaChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        var c = width / 2, rOut = width * 0.5, rIn = width * 0.37, n = 8;
                        ctx.reset();
                        ctx.fillStyle = tinta;
                        ctx.beginPath();
                        for (var k = 0; k < n; k++) {
                            var a = k * 2 * Math.PI / n, t = Math.PI / n;
                            var pts = [[rIn, a - t * 0.62], [rOut, a - t * 0.42], [rOut, a + t * 0.42], [rIn, a + t * 0.62]];
                            for (var p = 0; p < pts.length; p++) {
                                var x = c + pts[p][0] * Math.cos(pts[p][1]), y = c + pts[p][0] * Math.sin(pts[p][1]);
                                if (k === 0 && p === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            }
                        }
                        ctx.closePath();
                        ctx.fill();
                        ctx.beginPath();
                        ctx.arc(c, c, rIn, 0, 2 * Math.PI);
                        ctx.fill();
                        // Hueco del centro
                        ctx.globalCompositeOperation = "destination-out";
                        ctx.beginPath();
                        ctx.arc(c, c, width * 0.17, 0, 2 * Math.PI);
                        ctx.fill();
                        ctx.globalCompositeOperation = "source-over";
                    }
                }

                MouseArea {
                    id: zona
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.actual = index
                    onClicked: {
                        root.actual = index;
                        root.forceActiveFocus();
                        root.activar(index);
                    }
                }
            }
        }
    }
}
