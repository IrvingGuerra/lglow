import QtQuick 2.6
import QtGraphicalEffects 1.0

// [fullhome-custom] Parte de abajo del home: todas las apps. Con el home en reposo se asoma
// la primera fila, cortada por el borde de la pantalla. Al bajar desde la fila de apps (o con
// un clic en lo que se asoma), MainView desliza todo hacia arriba como un scroll; Atrás, o ↑
// desde la primera fila, regresa.
FocusScope {

    id: root

    property bool open: false
    // 0 = asomada abajo del home, 1 = ocupa la pantalla. La anima MainView.
    property real progress: 0
    // Cuánto se asoma la primera fila con el home en reposo
    property int peek: styleSheet.getRValue(64)
    // Distancia del scroll: de asomada a pantalla completa
    readonly property real restY: height - grid.y - peek

    signal closed()

    y: (1 - progress) * restY

    // El compositor solo le pasa la tecla Atrás al home si su ventana lo declara. El binario
    // del home ya lo declara por su cuenta; aquí solo nos aseguramos al abrir, y nunca lo
    // apagamos (apagarlo rompería Atrás en el modo edición de LG y en el resto del home).
    onOpenChanged: {
        if (open)
            rootWindow.setWindowProperty("_WEBOS_ACCESS_POLICY_KEYS_BACK", "true");
    }

    function show() {
        open = true;
        grid.reset();
        grid.forceActiveFocus();
    }

    function hide() {
        if (!open)
            return;
        open = false;
        closed();
    }

    // Si se abre una app (desde aquí o con un botón del control), regresa al home
    Connections {
        target: uiController
        onHomeShownChanged: {
            if (!uiController.homeShown)
                root.open = false;
        }
    }

    Connections {
        target: systemProperties
        onIsAppForegroundChanged: {
            if (!systemProperties.isAppForeground)
                root.open = false;
        }
    }

    // Sin fondo propio: el fondo del home se queda quieto y el contenido se desliza encima.
    // Que los clics del puntero no lleguen al home de abajo (solo con la parte abierta).
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.open
    }

    // Repisa "de vidrio" detrás de la cuadrícula, con sombra
    RectangularGlow {
        anchors.fill: repisa
        anchors.topMargin: styleSheet.getRValue(14)
        glowRadius: styleSheet.getRValue(36)
        spread: 0.05
        cornerRadius: repisa.radius + glowRadius
        color: lglowTema.sombra
    }

    Rectangle {
        id: repisa
        anchors.left: grid.left
        anchors.right: grid.right
        anchors.top: grid.top
        anchors.bottom: grid.bottom
        anchors.margins: -styleSheet.getRValue(36)
        radius: styleSheet.getRValue(48)
        color: lglowTema.repisa
        border.color: lglowTema.repisaBorde
        border.width: styleSheet.getRValue(2)
    }

    // Arriba queda asomado el borde de la fila fijada: pista de que ↑ regresa
    AppGrid {
        id: grid
        mode: "all"
        anchors.horizontalCenter: parent.horizontalCenter
        y: styleSheet.getRValue(130)
        onCloseAll: root.hide()
    }

    Text {
        anchors.left: grid.left
        anchors.top: grid.bottom
        anchors.topMargin: styleSheet.getRValue(64)
        opacity: root.progress
        text: grid.lpModel.count + " apps  ·  ↑ o Atrás para regresar  ·  ✎ para reordenar"
        color: lglowTema.textoSuave
        font.family: fontManager.smart_Regular.family
        font.pixelSize: styleSheet.getRValue(26)
    }

    // Con el home en reposo, un clic en lo que se asoma baja a las apps. También absorbe el
    // hover, para que los tiles asomados no le roben el foco a la fila de arriba.
    MouseArea {
        anchors.fill: repisa
        z: 10
        enabled: !root.open
        hoverEnabled: true
        onClicked: root.show()
    }
}
