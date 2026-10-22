import QtQuick 2.6
import QtGraphicalEffects 1.0

// [fullhome-custom] Menú propio de LGlow: el tema del home (claro, oscuro o automático).
// Se abre con el botón de tema de arriba; OK elige, Atrás o ↑ desde la primera opción cierra.
FocusScope {

    id: root

    property bool open: false
    property int actual: 0
    property int derecha: 0             // borde derecho de la tarjeta (alineado con los botones)
    property int arriba: 0
    readonly property var opciones: [
        { "modo": "claro", "nombre": "Claro", "nota": "Siempre claro" },
        { "modo": "oscuro", "nombre": "Oscuro", "nota": "Siempre oscuro" },
        { "modo": "auto", "nombre": "Automático", "nota": "Claro de día, oscuro de noche" }
    ]

    signal cerrado()

    visible: open || tarjeta.opacity > 0
    enabled: open

    function abrir() {
        for (var i = 0; i < opciones.length; i++)
            if (opciones[i].modo === lglowTema.modo)
                actual = i;
        open = true;
        root.forceActiveFocus();
    }

    function cerrar() {
        if (!open)
            return;
        open = false;
        cerrado();
    }

    function esAtras(key) {
        return key === uiController.webOS.Key_webOS_Back || key === Qt.Key_Back
            || key === Qt.Key_Escape || key === Qt.Key_Backspace;
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Up:
            if (actual > 0) actual--; else cerrar();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (actual < opciones.length - 1) actual++;
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            lglowTema.elegir(opciones[actual].modo);
            cerrar();
            event.accepted = true;
            break;
        default:
            if (esAtras(event.key))
                event.accepted = true;
            break;
        }
    }

    // Igual que la pantalla de apps: LG cierra el home al *soltar* Atrás
    Keys.onReleased: {
        if (esAtras(event.key)) {
            cerrar();
            event.accepted = true;
        }
    }

    // Velo: un clic fuera de la tarjeta cierra
    Rectangle {
        anchors.fill: parent
        color: lglowTema.velo
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.cerrar()
        }
    }

    Item {

        id: tarjeta

        x: root.derecha - width
        y: root.arriba
        width: styleSheet.getRValue(520)
        height: columna.height + 2 * styleSheet.getRValue(28)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        RectangularGlow {
            anchors.fill: parent
            anchors.topMargin: styleSheet.getRValue(10)
            glowRadius: styleSheet.getRValue(40)
            spread: 0.05
            cornerRadius: styleSheet.getRValue(32) + glowRadius
            color: lglowTema.sombra
        }

        Rectangle {
            anchors.fill: parent
            radius: styleSheet.getRValue(32)
            color: lglowTema.pastilla
        }

        // Que los clics en la tarjeta no la cierren
        MouseArea {
            anchors.fill: parent
        }

        Column {

            id: columna

            x: styleSheet.getRValue(16)
            y: styleSheet.getRValue(28)
            width: parent.width - 2 * x
            spacing: styleSheet.getRValue(4)

            Text {
                x: styleSheet.getRValue(20)
                text: "Tema"
                color: lglowTema.texto
                font.family: fontManager.smart_Bold.family
                font.weight: fontManager.smart_Bold.weight
                font.pixelSize: styleSheet.getRValue(34)
            }

            Item { width: 1; height: styleSheet.getRValue(8) }

            Repeater {
                model: root.opciones

                delegate: Item {

                    id: opcion

                    property bool sel: root.actual === index
                    property bool elegida: lglowTema.modo === modelData.modo

                    width: columna.width
                    height: styleSheet.getRValue(92)

                    Rectangle {
                        anchors.fill: parent
                        radius: styleSheet.getRValue(20)
                        color: lglowTema.texto
                        opacity: opcion.sel ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    // Radio
                    Rectangle {
                        id: radio
                        x: styleSheet.getRValue(20)
                        anchors.verticalCenter: parent.verticalCenter
                        width: styleSheet.getRValue(34)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: styleSheet.getRValue(3)
                        border.color: opcion.elegida ? "#FF4F8B" : lglowTema.textoSuave

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: width
                            radius: width / 2
                            color: "#FF4F8B"
                            visible: opcion.elegida
                        }
                    }

                    Column {
                        anchors.left: radio.right
                        anchors.leftMargin: styleSheet.getRValue(20)
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: modelData.nombre
                            color: lglowTema.texto
                            font.family: opcion.sel ? fontManager.smart_SemiBold.family : fontManager.smart_Regular.family
                            font.weight: opcion.sel ? fontManager.smart_SemiBold.weight : fontManager.smart_Regular.weight
                            font.pixelSize: styleSheet.getRValue(30)
                        }

                        Text {
                            text: modelData.nota
                            color: lglowTema.textoSuave
                            font.family: fontManager.smart_Regular.family
                            font.pixelSize: styleSheet.getRValue(22)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.actual = index
                        onClicked: {
                            lglowTema.elegir(modelData.modo);
                            root.cerrar();
                        }
                    }
                }
            }
        }
    }
}
