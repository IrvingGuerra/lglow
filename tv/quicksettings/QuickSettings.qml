import QtQuick 2.6
import QtGraphicalEffects 1.0
import WebOSServices 1.0
import YSM.SystemUI 1.0


// [lglow] Panel rápido de LGlow en lugar de los ajustes rápidos de LG. Lo abre el botón de
// engranaje del control, sobre cualquier entrada. Se monta encima del original (no reemplaza
// nada en la partición de LG) con tv/compositor.sh. Corre dentro del compositor (surface-manager),
// así que conserva el contrato de LG: se precarga al encender (y se cierra solo), onLaunch lo
// muestra (o lo cierra si ya estaba abierto) y exit() lo termina.
StarfishSystemUIWindow {

    id: root

    Connections {
        target: root.lifeCycleStatus
        onLaunch: {
            webOSShell.setWindowProperty('delayCloseWindowTimeout', 1000);
            webOSShell.setWindowProperty('legacyWindowName', "quickSetting");
            if (payload.reason === 'preload') {
                root.exit();
                return;
            }
            if (panel.open && payload.params === undefined) {
                panel.cerrar();
                return;
            }
            root.show();
            panel.abrir(payload.params);
        }
        onClose: {
            if (payload.reason === 'powerSuspend')
                root.exit();
            else
                panel.cerrar();
        }
    }

    FocusScope {

        id: panel

        property bool open: false
        property int actual: 0
        property int entradaActual: 0
        property var valores: ({ "imagen": "", "sonido": "", "apagado": 0 })
        property var entradas: []

        readonly property string fuente: "LG Smart UI"
        readonly property color texto: "#F5F5F7"
        readonly property color suave: "#A1A1AA"
        readonly property color fondoHoja: "#2C2C36"
        readonly property color chip: "#4A4A58"
        readonly property color acento: "#FF4F8B"

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
            { "id": "entrada", "nombre": "Entrada", "opciones": [] },
            { "id": "todos", "nombre": "Todos los ajustes de la TV", "opciones": [] }
        ]

        width: 1920
        height: 1080
        focus: true

        function abrir(params) {
            actual = 0;
            // Atajos del control que abren los ajustes rápidos en una opción
            var tipo = params && params.activateType ? String(params.activateType).toLowerCase() : "";
            if (tipo.indexOf("picture") !== -1) actual = 0;
            else if (tipo.indexOf("sound") !== -1) actual = 1;
            else if (tipo.indexOf("sleep") !== -1 || tipo.indexOf("timer") !== -1) actual = 2;
            open = true;
            panel.forceActiveFocus();
            leer();
        }

        function cerrar() {
            if (!open) {
                root.exit();
                return;
            }
            open = false;
            salida.restart();
        }

        // Espera a que termine la animación antes de soltar la ventana
        Timer {
            id: salida
            interval: 340
            onTriggered: if (!panel.open) root.exit()
        }

        function esAtras(key) {
            return key === Qt.Key_Escape || key === Qt.Key_Back || key === Qt.Key_Backspace
                || key === 18874371;
        }

        Component {
            id: llamada
            Service {
                property var cb
                appId: "com.webos.app.quicksettings"
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
            var s = llamada.createObject(panel, { "cb": cb || null });
            s.call("luna://" + servicio + "/", metodo, JSON.stringify(params));
        }

        function leer() {
            luna("com.webos.settingsservice", "getSystemSettings", { "category": "picture", "keys": ["pictureMode"] }, function(r) {
                if (r && r.settings) panel.poner("imagen", r.settings.pictureMode);
            });
            luna("com.webos.settingsservice", "getSystemSettings", { "category": "sound", "keys": ["soundMode"] }, function(r) {
                if (r && r.settings) panel.poner("sonido", r.settings.soundMode);
            });
            luna("com.webos.service.tv.time", "getSleepTimeInfo", {}, function(r) {
                // El tiempo que falta viene partido en minutos y segundos (9 y 58 = 9:58)
                if (r && r.sleepTimeSecond !== undefined)
                    panel.poner("apagado", Math.ceil(((+r.sleepTimeMinute || 0) * 60 + (+r.sleepTimeSecond)) / 60));
            });
            luna("com.webos.service.eim", "getAllInputStatus", {}, function(r) {
                var lista = [{ "label": "TV", "appId": "com.webos.app.livetv" }];
                var d = (r && r.devices) || [];
                for (var i = 0; i < d.length; i++)
                    if (d[i].id && d[i].id.indexOf("HDMI") === 0)
                        lista.push({ "label": d[i].label, "appId": d[i].appId });
                panel.entradas = lista;
            });
        }

        function poner(k, v) {
            var copia = {};
            for (var x in valores) copia[x] = valores[x];
            copia[k] = v;
            valores = copia;
        }

        function indice(fila) {
            var v = valores[fila.id], o = fila.opciones;
            for (var i = 0; i < o.length; i++)
                if (fila.id === "apagado" ? o[i][0] >= v : o[i][0] === v)
                    return i;
            return -1;
        }

        function textoDe(fila) {
            var i = indice(fila);
            if (i >= 0)
                return fila.opciones[i][1];
            return fila.id === "apagado" ? valores.apagado + " min" : (valores[fila.id] || "…");
        }

        function cambiar(fila, paso) {
            var o = fila.opciones;
            if (o.length === 0)
                return;
            var i = indice(fila);
            i = i < 0 ? 0 : (i + paso + o.length) % o.length;
            var v = o[i][0];
            poner(fila.id, v);
            if (fila.id === "imagen")
                luna("com.webos.settingsservice", "setSystemSettings", { "category": "picture", "settings": { "pictureMode": v } });
            else if (fila.id === "sonido")
                luna("com.webos.settingsservice", "setSystemSettings", { "category": "sound", "settings": { "soundMode": v } });
            else if (fila.id === "apagado")
                luna("com.webos.service.tv.time", "setSleepTimeInfo", { "sleepTimeMinute": v });
        }

        function lanzar(appId) {
            cerrar();
            luna("com.webos.applicationManager", "launch", { "id": appId });
        }

        function activar(fila) {
            if (fila.id === "entrada") {
                var e = entradas[entradaActual];
                if (e) lanzar(e.appId);
            } else if (fila.id === "todos") {
                lanzar("com.palm.app.settings");
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

        Keys.onReleased: {
            if (esAtras(event.key)) {
                cerrar();
                event.accepted = true;
            }
        }

        // Velo: un clic fuera de la hoja cierra
        Rectangle {
            anchors.fill: parent
            color: "#59000000"
            opacity: panel.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                onClicked: panel.cerrar()
            }
        }

        Item {

            id: hoja

            width: 680
            height: parent.height - 64
            y: 32
            x: panel.open ? parent.width - width - 32 : parent.width + 40
            Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            RectangularGlow {
                anchors.fill: parent
                glowRadius: 40
                spread: 0.05
                cornerRadius: 80
                color: "#70000000"
            }

            Rectangle {
                anchors.fill: parent
                radius: 40
                color: panel.fondoHoja
            }

            MouseArea {
                anchors.fill: parent
            }

            Text {
                id: titulo
                x: 44
                y: 40
                text: "Ajustes rápidos"
                color: panel.texto
                font.family: panel.fuente
                font.weight: Font.Bold
                font.pixelSize: 44
            }

            Text {
                x: 44
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                text: "← → cambia  ·  OK elige  ·  Atrás cierra"
                color: panel.suave
                font.family: panel.fuente
                font.pixelSize: 24
            }

            Column {

                anchors.top: titulo.bottom
                anchors.topMargin: 28
                x: 20
                width: parent.width - 40
                spacing: 6

                Repeater {
                    model: panel.filas

                    delegate: Item {

                        id: fila

                        property var datos: modelData
                        property int fi: index
                        property bool sel: panel.actual === index
                        property bool esEntrada: datos.id === "entrada"
                        property bool esTodos: datos.id === "todos"

                        width: parent.width
                        height: esEntrada ? 176 : 104

                        Rectangle {
                            anchors.fill: parent
                            radius: 26
                            color: panel.texto
                            opacity: fila.sel ? 0.08 : 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: panel.actual = fila.fi
                            onClicked: if (!fila.esEntrada) panel.activar(fila.datos)
                        }

                        Text {
                            x: 24
                            y: fila.esEntrada ? 20 : (104 - height) / 2
                            text: fila.datos.nombre
                            color: panel.texto
                            font.family: panel.fuente
                            font.weight: fila.sel ? Font.DemiBold : Font.Normal
                            font.pixelSize: 30
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            visible: !fila.esEntrada && !fila.esTodos

                            Item {
                                width: 52
                                height: 58
                                Text { anchors.centerIn: parent; text: "‹"; color: fila.sel ? panel.texto : panel.suave; font.pixelSize: 44 }
                                MouseArea { anchors.fill: parent; onClicked: { panel.actual = fila.fi; panel.cambiar(fila.datos, -1); } }
                            }

                            Rectangle {
                                width: Math.max(150, valorTexto.width + 44)
                                height: 58
                                radius: 29
                                color: fila.sel ? panel.acento : panel.chip

                                Text {
                                    id: valorTexto
                                    anchors.centerIn: parent
                                    text: panel.textoDe(fila.datos)
                                    color: panel.texto
                                    font.family: panel.fuente
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 27
                                }
                            }

                            Item {
                                width: 52
                                height: 58
                                Text { anchors.centerIn: parent; text: "›"; color: fila.sel ? panel.texto : panel.suave; font.pixelSize: 44 }
                                MouseArea { anchors.fill: parent; onClicked: { panel.actual = fila.fi; panel.cambiar(fila.datos, 1); } }
                            }
                        }

                        Row {
                            x: 24
                            y: 84
                            spacing: 12
                            visible: fila.esEntrada

                            Repeater {
                                model: panel.entradas
                                delegate: Rectangle {
                                    property bool marcada: fila.sel && panel.entradaActual === index
                                    width: nombreEntrada.width + 48
                                    height: 62
                                    radius: 31
                                    color: marcada ? panel.acento : panel.chip
                                    scale: marcada ? 1.06 : 1

                                    Text {
                                        id: nombreEntrada
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: panel.texto
                                        font.family: panel.fuente
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 27
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: { panel.actual = fila.fi; panel.entradaActual = index; }
                                        onClicked: panel.activar(fila.datos)
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 28
                            anchors.verticalCenter: parent.verticalCenter
                            visible: fila.esTodos
                            text: "›"
                            color: panel.suave
                            font.pixelSize: 44
                        }
                    }
                }
            }
        }
    }
}
