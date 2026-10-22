import QtQuick 2.6
import QtGraphicalEffects 1.0
import QtGraphicalEffects 1.0

// [fullhome-custom] Encabezado estilo Free My TV: "Para ti", pestañas Explorar /
// Películas / Series, fecha, hora, clima y tres títulos en tendencia que están en
// las apps de esta TV (uno ancho y dos pósters, con título debajo). Con foco: ←/→
// cambian pestaña o título, ↓/↑ bajan y suben,
// OK en un título abre su app.
//   - Clima: Open-Meteo (sin llave), cada 30 min.
//   - Tendencias: TMDB (/trending/<tipo>/week + watch/providers de la región), cada hora.
// La configuración vive fuera del código, en la TV:
//   /var/lib/webosbrew/fullhomecustom/config.json
//   {"tmdbKey": "...", "region": "MX", "language": "es-MX",
//    "latitude": 19.4326, "longitude": -99.1332, "city": "Ciudad de México",
//    "providers": {"8": ["Netflix", "netflix"], ...}}   ← opcional
// Sin tmdbKey solo se muestran fecha, hora y clima.
FocusScope {

    id: root

    signal exitUp()     // ↑ desde las pestañas: a los íconos de arriba
    signal exitDown()   // ↓ desde los títulos: a la cuadrícula de apps

    property var config: ({})
    property string clock: ""
    property string dateText: ""
    property string weatherText: ""
    property var tabs: [{ "name": "Explorar", "kind": "all" },
                        { "name": "Películas", "kind": "movie" },
                        { "name": "Series", "kind": "tv" }]
    property int tabIndex: 0
    property var pools: ({})        // tipo → títulos válidos de la semana
    property bool loading: false    // se están consultando las tendencias de la pestaña actual
    property var picks: []          // [{title, backdrop, poster, kind, app, appId}]
    property int pickGap: styleSheet.getRValue(40)
    // Uno ancho (imagen de fondo) y dos pósters 2:3, todos de la misma altura, que
    // ocupan exactamente el ancho de la fila de apps
    property int pickHeight: styleSheet.getRValue(404)
    property int posterWidth: Math.round(pickHeight * 2 / 3)
    property int wideWidth: width - 2 * posterWidth - 2 * pickGap
    readonly property bool canFocus: picks.length > 0 || !!config.tmdbKey

    readonly property color textColor: lglowTema.texto
    readonly property color softColor: lglowTema.textoSuave
    readonly property string configPath: "file:///var/lib/webosbrew/fullhomecustom/config.json"

    // Proveedor de TMDB → [nombre visible, appId en la TV]. Se puede reemplazar con
    // "providers" en config.json (los ids cambian según el país); estos son los de México.
    readonly property var providers: config.providers || defaultProviders
    readonly property var defaultProviders: ({
        "8": ["Netflix", "netflix"], "1796": ["Netflix", "netflix"],
        "337": ["Disney+", "com.disney.disneyplus-prod"],
        "1899": ["Max", "com.wbd.stream"], "1825": ["Max", "com.wbd.stream"],
        "119": ["Prime Video", "amazon"], "2100": ["Prime Video", "amazon"],
        "457": ["ViX", "vix"], "1866": ["ViX", "vix"],
        "283": ["Crunchyroll", "com.crunchyroll.webapp"], "1968": ["Crunchyroll", "com.crunchyroll.webapp"],
        "167": ["Claro video", "clarovideo.dla.1"],
        "538": ["Plex", "cdp-30"]
    })

    readonly property var days: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
    readonly property var months: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
                                   "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

    height: picksRow.y + picksRow.height

    function focusTabs() {
        tabRow.forceActiveFocus();
    }

    function focusPicks() {
        if (picks.length > 0)
            picksRow.forceActiveFocus();
        else
            tabRow.forceActiveFocus();
    }

    function get(url, done) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            var data = null;
            try { data = JSON.parse(xhr.responseText); } catch (e) {}
            done(data);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function tick() {
        var d = new Date();
        root.clock = Qt.formatTime(d, "HH:mm");
        var t = days[d.getDay()] + " " + d.getDate() + " de " + months[d.getMonth()];
        root.dateText = t.charAt(0).toUpperCase() + t.slice(1);
    }

    // Código WMO de Open-Meteo → texto corto
    function weatherName(code) {
        if (code === 0) return "Despejado";
        if (code <= 2) return "Parcialmente nublado";
        if (code === 3) return "Nublado";
        if (code <= 48) return "Neblina";
        if (code <= 57) return "Llovizna";
        if (code <= 67) return "Lluvia";
        if (code <= 77) return "Nieve";
        if (code <= 82) return "Chubascos";
        return "Tormenta";
    }

    function loadWeather() {
        if (config.latitude === undefined)
            return;
        get("https://api.open-meteo.com/v1/forecast?latitude=" + config.latitude + "&longitude=" + config.longitude
            + "&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=1",
            function(r) {
                if (!r || !r.current)
                    return;
                var t = Math.round(r.current.temperature_2m) + "°  " + weatherName(r.current.weather_code);
                if (r.daily && r.daily.sunrise)
                    lglowTema.ponerSol(r.daily.sunrise[0], r.daily.sunset[0]); // para el tema automático
                if (r.daily)
                    t += "  ·  " + Math.round(r.daily.temperature_2m_max[0]) + "° / " + Math.round(r.daily.temperature_2m_min[0]) + "°";
                if (config.city)
                    t += "  ·  " + config.city;
                root.weatherText = t;
            });
    }

    function tmdb(path, done) {
        var sep = path.indexOf("?") === -1 ? "?" : "&";
        get("https://api.themoviedb.org/3" + path + sep + "api_key=" + config.tmdbKey, done);
    }

    // Revisa los títulos en orden y guarda los que están en alguna app de la TV
    function loadPool(kind, force) {
        if (!config.tmdbKey)
            return;
        if (pools[kind] && !force) {
            if (kind === tabs[tabIndex].kind)
                rotate();
            return;
        }
        var lang = config.language || "es-MX", region = config.region || "MX";
        var found = [];
        if (kind === tabs[tabIndex].kind)
            root.loading = true;
        // Recorre hasta 3 páginas de tendencias (20 c/u) hasta juntar 9 títulos en tus apps
        function page(n) {
            tmdb("/trending/" + kind + "/week?language=" + lang + "&page=" + n, function(r) {
                if (!r || !r.results) {
                    done();
                    return;
                }
                var items = r.results.filter(function(it) {
                    var type = it.media_type || kind;
                    return (type === "movie" || type === "tv") && it.backdrop_path && it.poster_path;
                });
                function next(i) {
                    if (found.length >= 9)
                        return done();
                    if (i >= items.length)
                        return n < 3 ? page(n + 1) : done();
                    var it = items[i], type = it.media_type || kind;
                    tmdb("/" + type + "/" + it.id + "/watch/providers", function(pr) {
                        var here = pr && pr.results && pr.results[region];
                        var flat = (here && here.flatrate) || [];
                        for (var k = 0; k < flat.length; k++) {
                            var app = providers[String(flat[k].provider_id)];
                            if (app) {
                                found.push({
                                    "title": it.title || it.name,
                                    "backdrop": "https://image.tmdb.org/t/p/w1280" + it.backdrop_path,
                                    "poster": "https://image.tmdb.org/t/p/w342" + it.poster_path,
                                    "kind": type === "tv" ? "Serie" : "Película",
                                    "app": app[0],
                                    "appId": app[1]
                                });
                                break;
                            }
                        }
                        next(i + 1);
                    });
                }
                next(0);
            });
        }
        function done() {
            var p = root.pools;
            p[kind] = found;
            root.pools = p;
            if (kind === tabs[tabIndex].kind) {
                root.loading = false;
                rotate();
            }
        }
        page(1);
    }

    // Cada hora muestra otros tres de la lista de la semana
    function rotate() {
        var pool = pools[tabs[tabIndex].kind] || [];
        if (pool.length === 0) {
            root.picks = [];
            return;
        }
        var start = (new Date().getHours() * 3) % pool.length;
        var out = [];
        for (var i = 0; i < Math.min(3, pool.length); i++)
            out.push(pool[(start + i) % pool.length]);
        root.picks = out;
    }

    function selectTab(i) {
        if (i < 0 || i >= tabs.length || i === tabIndex)
            return;
        tabIndex = i;
        root.loading = false;
        rotate();                       // vacía los títulos si esta pestaña aún no tiene datos
        loadPool(tabs[i].kind, false);
    }

    function openPick(i) {
        var pick = picks[i];
        if (!pick)
            return;
        var lps = systemProperties.launchPoints || [];
        for (var k = 0; k < lps.length; k++) {
            if (lps[k].id === pick.appId) {
                interfaces.launchPoints.doLaunch(lps[k]);
                return;
            }
        }
    }

    Component.onCompleted: {
        tick();
        get(configPath, function(c) {
            root.config = c || {};
            loadWeather();
            loadPool(tabs[tabIndex].kind, false);
        });
    }

    Timer { interval: 15000; running: true; repeat: true; onTriggered: root.tick() }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.loadWeather() }
    Timer {
        interval: 60 * 60 * 1000; running: true; repeat: true
        onTriggered: {
            root.pools = {};
            root.loadPool(root.tabs[root.tabIndex].kind, true);
        }
    }

    Text {
        id: title
        x: 0
        y: 0
        text: "Para ti"
        color: root.textColor
        font.family: fontManager.smart_Bold.family
        font.weight: fontManager.smart_Bold.weight
        font.pixelSize: styleSheet.getRValue(72)
    }

    // Pestañas: la activa en una píldora con sombra; con foco, la píldora crece
    FocusScope {

        id: tabRow

        property int focusIndex: root.tabIndex

        anchors.left: title.left
        anchors.leftMargin: -styleSheet.getRValue(18)
        anchors.top: title.bottom
        anchors.topMargin: styleSheet.getRValue(24)
        width: tabsLayout.width
        height: styleSheet.getRValue(52)

        onActiveFocusChanged: if (activeFocus) focusIndex = root.tabIndex

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_Left:
                root.selectTab(root.tabIndex - 1);
                event.accepted = true;
                break;
            case Qt.Key_Right:
                root.selectTab(root.tabIndex + 1);
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.focusPicks();
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.exitUp();
                event.accepted = true;
                break;
            }
        }

        Row {
            id: tabsLayout
            height: parent.height
            spacing: styleSheet.getRValue(6)

            Repeater {
                model: root.tabs

                delegate: Item {
                    property bool current: index === root.tabIndex
                    width: label.width + styleSheet.getRValue(36)
                    height: tabsLayout.height

                    RectangularGlow {
                        anchors.fill: pill
                        anchors.topMargin: styleSheet.getRValue(4)
                        glowRadius: styleSheet.getRValue(14)
                        spread: 0.1
                        cornerRadius: pill.radius + glowRadius
                        color: lglowTema.sombra
                        visible: pill.visible
                        opacity: tabRow.activeFocus ? 1 : 0.7
                    }

                    Rectangle {
                        id: pill
                        anchors.fill: parent
                        radius: height / 2
                        color: lglowTema.pastilla
                        visible: parent.current
                        scale: tabRow.activeFocus ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.name
                        color: parent.current ? root.textColor : root.softColor
                        font.family: parent.current ? fontManager.smart_SemiBold.family : fontManager.smart_Regular.family
                        font.weight: parent.current ? fontManager.smart_SemiBold.weight : fontManager.smart_Regular.weight
                        font.pixelSize: styleSheet.getRValue(30)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.selectTab(index); tabRow.forceActiveFocus(); }
                    }
                }
            }
        }
    }

    Text {
        id: info
        anchors.right: parent.right
        anchors.verticalCenter: tabRow.verticalCenter
        text: root.dateText + "   " + root.clock + (root.weatherText ? "     " + root.weatherText : "")
        color: root.softColor
        font.family: fontManager.smart_Regular.family
        font.pixelSize: styleSheet.getRValue(26)
    }

    // Títulos en tendencia: con foco crecen y llevan borde blanco; OK abre su app
    FocusScope {

        id: picksRow

        property int focusIndex: 0

        anchors.left: parent.left
        anchors.top: tabRow.bottom
        anchors.topMargin: styleSheet.getRValue(56) // aire para que el título con foco no toque las pestañas
        width: parent.width
        height: root.pickHeight + styleSheet.getRValue(84)

        onActiveFocusChanged: if (activeFocus) focusIndex = Math.min(focusIndex, Math.max(0, root.picks.length - 1))

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_Left:
                if (focusIndex > 0) focusIndex--;
                event.accepted = true;
                break;
            case Qt.Key_Right:
                if (focusIndex < root.picks.length - 1) focusIndex++;
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.focusTabs();
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.exitDown();
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.openPick(focusIndex);
                event.accepted = true;
                break;
            }
        }

        Row {
            spacing: root.pickGap
            visible: root.picks.length === 0 && root.loading

            Repeater {
                model: 3
                delegate: Rectangle {
                    width: index === 0 ? root.wideWidth : root.posterWidth
                    height: root.pickHeight
                    radius: styleSheet.getRValue(22)
                    color: lglowTema.esqueleto

                    SequentialAnimation on opacity {
                        running: parent.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.45; duration: 700; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.45; to: 1; duration: 700; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }

        Row {
            id: picksShown
            spacing: root.pickGap

            // Al cambiar de pestaña (o de hora) los títulos nuevos entran con un fundido
            Connections {
                target: root
                onPicksChanged: picksIn.restart()
            }

            ParallelAnimation {
                id: picksIn
                NumberAnimation { target: picksShown; property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutQuad }
                NumberAnimation { target: picksShown; property: "x"; from: styleSheet.getRValue(40); to: 0; duration: 380; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: root.picks

                delegate: Item {
                    id: pick

                    property bool selected: picksRow.activeFocus && index === picksRow.focusIndex
                    property bool wide: index === 0

                    width: wide ? root.wideWidth : root.posterWidth
                    height: picksRow.height
                    z: selected ? 2 : 1

                    Item {
                        id: card
                        width: parent.width
                        height: root.pickHeight
                        scale: pick.selected ? 1.04 : 1
                        transformOrigin: Item.Bottom

                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                        // Sombra y borde blanco del título con foco
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: styleSheet.getRValue(16)
                            anchors.bottomMargin: -styleSheet.getRValue(14)
                            radius: styleSheet.getRValue(26)
                            color: "#30000000"
                            visible: pick.selected
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -styleSheet.getRValue(5)
                            radius: styleSheet.getRValue(27)
                            color: "#FFFFFF"
                            visible: pick.selected
                        }

                        // Imagen con esquinas redondeadas (OpacityMask sobre un Rectangle redondeado)
                        Rectangle {
                            id: frame
                            anchors.fill: parent
                            radius: styleSheet.getRValue(22)
                            color: lglowTema.esqueletoSuave
                        }

                        Image {
                            id: poster
                            anchors.fill: parent
                            source: pick.wide ? modelData.backdrop : modelData.poster
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: poster
                            maskSource: frame
                            visible: poster.status === Image.Ready
                        }
                    }

                    Text {
                        id: caption
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: card.bottom
                        anchors.topMargin: styleSheet.getRValue(14)
                        text: modelData.title
                        elide: Text.ElideRight
                        color: root.textColor
                        font.family: fontManager.smart_SemiBold.family
                        font.weight: fontManager.smart_SemiBold.weight
                        font.pixelSize: styleSheet.getRValue(32)
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: caption.bottom
                        anchors.topMargin: styleSheet.getRValue(2)
                        text: modelData.kind + "  ·  " + modelData.app
                        elide: Text.ElideRight
                        color: root.softColor
                        font.family: fontManager.smart_Regular.family
                        font.pixelSize: styleSheet.getRValue(24)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { picksRow.focusIndex = index; picksRow.forceActiveFocus(); }
                        onClicked: root.openPick(index)
                    }
                }
            }
        }
    }
}
