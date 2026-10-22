import QtQuick 2.6
import QtGraphicalEffects 1.0
import WebOSServices 1.0

// [fullhome-custom] Panel rápido de LGlow: lo más usado de la configuración en un solo lugar,
// sin submenús. ↑ ↓ entre filas, ← → cambia el valor (se aplica al momento), OK en una
// entrada la abre y Atrás cierra. Entra desde la derecha con el botón de engranaje.
FocusScope {

    id: root

    property bool open: false
    property int actual: 0
    property int entradaActual: 0
    // Valores actuales de la TV (se leen al abrir)
    property var valores: ({ "imagen": "", "sonido": "", "apagado": 0 })
    property var entradas: []           // [{label, appId}]

    readonly property var filas: [
        { "id": "imagen", "nombre": "Modo de imagen", "opciones": [
            ["vivid", "Vívido"], ["normal", "Estándar"], ["eco", "Ahorro"],
            ["cinema", "Cine"], ["sports", "Deportes"], ["game", "Juegos"]] },
        { "id": "sonido", "nombre": "Modo de sonido", "opciones": [
            ["standard", "Estándar"], ["movie", "Cine"], ["news", "Noticias"],
            ["sports", "Deportes"], ["music", "Música"], ["game", "Juegos"]] },
        { "id": "apagado", "nombre": "Apagado automático", "opciones": [
            [0, "No"], [10, "10 min"], [20, "20 min"], [30, "30 min"], [60, "1 hora"],
            [90, "1 h 30 min"], [120, "2 horas"], [180, "3 horas"]] },
        { "id": "tema", "nombre": "Tema del home", "opciones": [
            ["claro", "Claro"], ["oscuro", "Oscuro"], ["auto", "Automático"]] },
        { "id": "entrada", "nombre": "Entrada", "opciones": [] },
        { "id": "todos", "nombre": "Todos los ajustes de la TV", "opciones": [] }
    ]

    signal cerrado()

    visible: open || hoja.x < parent.width
    enabled: open

    function abrir() {
        actual = 0;
        open = true;
        root.forceActiveFocus();
        leer();
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

    // --- Servicios de la TV ---------------------------------------------------------------

    Component {
        id: llamada
        Service {
            property var cb
            appId: rootWindow.appId
            function responder(r) {
                if (typeof r === "string") {
                    try { r = JSON.parse(r); } catch (e) { r = null; }
                }
                if (cb) cb(r);
                destroy();
            }
            onCallSuccess: responder(response)
            onCallFailure: responder(null)
            onError: responder(null)
        }
    }

    function luna(servicio, metodo, params, cb) {
        var s = llamada.createObject(root, { "cb": cb || null });
        s.call("luna://" + servicio + "/", metodo, JSON.stringify(params));
    }

    function leer() {
        luna("com.webos.settingsservice", "getSystemSettings", { "category": "picture", "keys": ["pictureMode"] }, function(r) {
            if (r && r.settings) root.poner("imagen", r.settings.pictureMode);
        });
        luna("com.webos.settingsservice", "getSystemSettings", { "category": "sound", "keys": ["soundMode"] }, function(r) {
            if (r && r.settings) root.poner("sonido", r.settings.soundMode);
        });
        luna("com.webos.service.tv.time", "getSleepTimeInfo", {}, function(r) {
            // El tiempo que falta viene partido en minutos y segundos (9 y 58 = 9:58)
            if (r && r.sleepTimeSecond !== undefined)
                root.poner("apagado", Math.ceil(((+r.sleepTimeMinute || 0) * 60 + (+r.sleepTimeSecond)) / 60));
        });
        luna("com.webos.service.eim", "getAllInputStatus", {}, function(r) {
            var lista = [{ "label": "TV", "appId": "com.webos.app.livetv" }];
            var d = (r && r.devices) || [];
            for (var i = 0; i < d.length; i++)
                if (d[i].id && d[i].id.indexOf("HDMI") === 0)
                    lista.push({ "label": d[i].label, "appId": d[i].appId });
            root.entradas = lista;
        });
    }

    function poner(k, v) {
        var copia = {};
        for (var x in valores) copia[x] = valores[x];
        copia[k] = v;
        valores = copia;
    }

    function valor(fila) {
        return fila.id === "tema" ? lglowTema.modo : valores[fila.id];
    }

    // Índice de la opción actual (para el apagado, la primera que alcanza los minutos que faltan)
    function indice(fila) {
        var v = valor(fila), o = fila.opciones;
        for (var i = 0; i < o.length; i++) {
            if (fila.id === "apagado" ? o[i][0] >= v : o[i][0] === v)
                return i;
        }
        return -1;
    }

    function texto(fila) {
        var i = indice(fila);
        if (i >= 0)
            return fila.opciones[i][1];
        return fila.id === "apagado" ? valor(fila) + " min" : (valor(fila) || "…");
    }

    function cambiar(fila, paso) {
        var o = fila.opciones;
        if (o.length === 0)
            return;
        var i = indice(fila);
        i = i < 0 ? 0 : (i + paso + o.length) % o.length;
        var v = o[i][0];
        if (fila.id === "tema") {
            lglowTema.elegir(v);
            return;
        }
        poner(fila.id, v);
        if (fila.id === "imagen")
            luna("com.webos.settingsservice", "setSystemSettings", { "category": "picture", "settings": { "pictureMode": v } });
        else if (fila.id === "sonido")
            luna("com.webos.settingsservice", "setSystemSettings", { "category": "sound", "settings": { "soundMode": v } });
        else if (fila.id === "apagado")
            luna("com.webos.service.tv.time", "setSleepTimeInfo", { "sleepTimeMinute": v });
    }

    function activar(fila) {
        if (fila.id === "entrada") {
            var e = entradas[entradaActual];
            if (e) {
                cerrar();
                interfaces.application.launchApp(e.appId, "", {});
            }
        } else if (fila.id === "todos") {
            cerrar();
            interfaces.application.launchApp("com.palm.app.settings", "", {});
        } else {
            cambiar(fila, 1);
        }
    }

    Keys.onPressed: {
        var fila = filas[actual];
        switch (event.key) {
        case Qt.Key_Up:
            if (actual > 0) actual--;
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (actual < filas.length - 1) actual++;
            event.accepted = true;
            break;
        case Qt.Key_Left:
            if (fila.id === "entrada") { if (entradaActual > 0) entradaActual--; }
            else cambiar(fila, -1);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            if (fila.id === "entrada") { if (entradaActual < entradas.length - 1) entradaActual++; }
            else cambiar(fila, 1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            activar(fila);
            event.accepted = true;
            break;
        default:
            if (esAtras(event.key))
                event.accepted = true;
            break;
        }
    }

    // LG cierra el home al *soltar* Atrás: cerramos al soltar para que no llegue a LG
    Keys.onReleased: {
        if (esAtras(event.key)) {
            cerrar();
            event.accepted = true;
        }
    }

    // --- Vista --------------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: lglowTema.velo
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.cerrar()
        }
    }

    Item {

        id: hoja

        width: styleSheet.getRValue(680)
        height: parent.height - 2 * styleSheet.getRValue(32)
        y: styleSheet.getRValue(32)
        x: root.open ? parent.width - width - styleSheet.getRValue(32) : parent.width + styleSheet.getRValue(40)
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        RectangularGlow {
            anchors.fill: parent
            glowRadius: styleSheet.getRValue(40)
            spread: 0.05
            cornerRadius: styleSheet.getRValue(40) + glowRadius
            color: lglowTema.sombra
        }

        Rectangle {
            anchors.fill: parent
            radius: styleSheet.getRValue(40)
            color: lglowTema.pastilla
        }

        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: titulo
            x: styleSheet.getRValue(44)
            y: styleSheet.getRValue(40)
            text: "Ajustes rápidos"
            color: lglowTema.texto
            font.family: fontManager.smart_Bold.family
            font.weight: fontManager.smart_Bold.weight
            font.pixelSize: styleSheet.getRValue(44)
        }

        Column {

            anchors.top: titulo.bottom
            anchors.topMargin: styleSheet.getRValue(28)
            x: styleSheet.getRValue(20)
            width: parent.width - 2 * x
            spacing: styleSheet.getRValue(6)

            Repeater {
                model: root.filas

                delegate: Item {

                    id: fila

                    property var datos: modelData
                    property int fi: index
                    property bool sel: root.actual === index
                    property bool esEntrada: datos.id === "entrada"
                    property bool esTodos: datos.id === "todos"

                    width: parent.width
                    height: esEntrada ? styleSheet.getRValue(176) : styleSheet.getRValue(104)

                    Rectangle {
                        anchors.fill: parent
                        radius: styleSheet.getRValue(26)
                        color: lglowTema.texto
                        opacity: fila.sel && root.activeFocus ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.actual = fila.fi
                        onClicked: if (!fila.esEntrada) root.activar(fila.datos)
                    }

                    Text {
                        x: styleSheet.getRValue(24)
                        y: fila.esEntrada ? styleSheet.getRValue(20) : (styleSheet.getRValue(104) - height) / 2
                        text: fila.datos.nombre
                        color: lglowTema.texto
                        font.family: fila.sel ? fontManager.smart_SemiBold.family : fontManager.smart_Regular.family
                        font.weight: fila.sel ? fontManager.smart_SemiBold.weight : fontManager.smart_Regular.weight
                        font.pixelSize: styleSheet.getRValue(30)
                    }

                    // Valor con flechas: ‹ Cine ›
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: styleSheet.getRValue(12)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: styleSheet.getRValue(4)
                        visible: !fila.esEntrada && !fila.esTodos

                        Item {
                            width: styleSheet.getRValue(52)
                            height: styleSheet.getRValue(58)
                            Text {
                                anchors.centerIn: parent
                                text: "‹"
                                color: fila.sel ? lglowTema.texto : lglowTema.textoSuave
                                font.pixelSize: styleSheet.getRValue(44)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { root.actual = fila.fi; root.cambiar(fila.datos, -1); }
                            }
                        }

                        Rectangle {
                            width: Math.max(styleSheet.getRValue(150), valorTexto.width + styleSheet.getRValue(44))
                            height: styleSheet.getRValue(58)
                            radius: height / 2
                            color: fila.sel && root.activeFocus ? "#FF4F8B" : (lglowTema.oscuro ? "#4A4A58" : "#EEF0F4")
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                id: valorTexto
                                anchors.centerIn: parent
                                text: root.texto(fila.datos)
                                color: fila.sel && root.activeFocus ? "#FFFFFF" : lglowTema.texto
                                font.family: fontManager.smart_SemiBold.family
                                font.weight: fontManager.smart_SemiBold.weight
                                font.pixelSize: styleSheet.getRValue(27)
                            }
                        }

                        Item {
                            width: styleSheet.getRValue(52)
                            height: styleSheet.getRValue(58)
                            Text {
                                anchors.centerIn: parent
                                text: "›"
                                color: fila.sel ? lglowTema.texto : lglowTema.textoSuave
                                font.pixelSize: styleSheet.getRValue(44)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { root.actual = fila.fi; root.cambiar(fila.datos, 1); }
                            }
                        }
                    }

                    // Entradas: un botón por cada una; OK la abre
                    Row {
                        x: styleSheet.getRValue(24)
                        y: styleSheet.getRValue(84)
                        spacing: styleSheet.getRValue(12)
                        visible: fila.esEntrada

                        Repeater {
                            model: root.entradas
                            delegate: Rectangle {
                                property bool marcada: fila.sel && root.activeFocus && root.entradaActual === index
                                width: nombreEntrada.width + styleSheet.getRValue(48)
                                height: styleSheet.getRValue(62)
                                radius: height / 2
                                color: marcada ? "#FF4F8B" : (lglowTema.oscuro ? "#4A4A58" : "#EEF0F4")
                                scale: marcada ? 1.06 : 1
                                Behavior on scale { NumberAnimation { duration: 120 } }

                                Text {
                                    id: nombreEntrada
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.marcada ? "#FFFFFF" : lglowTema.texto
                                    font.family: fontManager.smart_SemiBold.family
                                    font.weight: fontManager.smart_SemiBold.weight
                                    font.pixelSize: styleSheet.getRValue(27)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: { root.actual = fila.fi; root.entradaActual = index; }
                                    onClicked: root.activar(fila.datos)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: styleSheet.getRValue(28)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: fila.esTodos
                        text: "›"
                        color: lglowTema.textoSuave
                        font.pixelSize: styleSheet.getRValue(44)
                    }
                }
            }
        }
    }
}
