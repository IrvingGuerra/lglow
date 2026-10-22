import QtQuick 2.6
import QtGraphicalEffects 1.0

// [fullhome-custom] Botones de arriba de LGlow, grandes para el puntero: el tema (abre el menú
// de LGlow) y el engranaje (va directo a la configuración completa de la TV, sin el panel
// rápido de la izquierda). Reemplaza a la fila de íconos de LG.
FocusScope {

    id: root

    property int actual: 1              // 0 = tema, 1 = engranaje
    property int lado: styleSheet.getRValue(84)
    // El símbolo del engranaje sale de la fila de LG, que usa la fuente de dingbats
    readonly property string engrane: {
        var lista = systemProperties.topGlobalActions || [];
        for (var i = 0; i < lista.length; i++)
            if (lista[i].type === "settings")
                return lista[i].buttonText;
        return "";
    }

    signal exitDown()
    signal abrirTema()

    width: fila.width
    height: lado

    function activar(i) {
        if (i === 0)
            root.abrirTema();
        else
            interfaces.application.launchApp("com.palm.app.settings", "", {});
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

                // Engranaje: el mismo símbolo que usa LG
                Text {
                    anchors.centerIn: parent
                    visible: index === 1
                    text: root.engrane
                    color: boton.sel ? lglowTema.pastilla : lglowTema.icono
                    font.family: fontManager.sandstone_Dingbat.family
                    font.pixelSize: Math.round(root.lado * 0.5)
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
