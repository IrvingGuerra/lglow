import QtQuick 2.6

// [fullhome-custom] Segunda "pantalla" del home: todas las apps. Se abre con el tile
// "Apps" de la fila del home y se cierra con Atrás (o ↑ desde la primera fila).
FocusScope {

    id: root

    property bool open: false

    signal closed()

    visible: open
    enabled: open

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

    // Si se abre una app (desde aquí o con un botón del control), esta pantalla se cierra
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

    // Fondo propio: tapa por completo la pantalla del home
    Image {
        anchors.fill: parent
        source: "file:///var/lib/webosbrew/fullhomecustom/fondo.jpg"
        fillMode: Image.PreserveAspectCrop
        cache: false
    }

    // Que los clics del puntero no lleguen al home de abajo
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    Text {
        id: title
        x: grid.x
        y: styleSheet.getRValue(56)
        text: "Apps"
        color: "#1D1D1F"
        font.family: fontManager.smart_Bold.family
        font.weight: fontManager.smart_Bold.weight
        font.pixelSize: styleSheet.getRValue(64)
    }

    Text {
        anchors.left: title.left
        anchors.top: title.bottom
        anchors.topMargin: styleSheet.getRValue(4)
        text: grid.lpModel.count + " apps  ·  Atrás para regresar  ·  ✎ para reordenar"
        color: "#6E6E73"
        font.family: fontManager.smart_Regular.family
        font.pixelSize: styleSheet.getRValue(26)
    }

    // Repisa "de vidrio" detrás de la cuadrícula
    Rectangle {
        anchors.left: grid.left
        anchors.right: grid.right
        anchors.top: grid.top
        anchors.bottom: grid.bottom
        anchors.margins: -styleSheet.getRValue(36)
        radius: styleSheet.getRValue(48)
        color: "#80FFFFFF"
        border.color: "#CCFFFFFF"
        border.width: styleSheet.getRValue(2)
    }

    AppGrid {
        id: grid
        mode: "all"
        anchors.horizontalCenter: parent.horizontalCenter
        y: styleSheet.getRValue(250)
        onCloseAll: root.hide()
    }
}
