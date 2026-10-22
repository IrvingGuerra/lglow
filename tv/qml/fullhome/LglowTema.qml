import QtQuick 2.6
import QtQuick.LocalStorage 2.0

// [fullhome-custom] Tema de LGlow: claro, oscuro o automático (claro de día, oscuro de noche,
// con el amanecer y el atardecer reales que Para ti trae de Open-Meteo). Los colores del home
// salen de aquí (lglowTema.texto, lglowTema.repisa…). La elección se guarda en LocalStorage.
QtObject {

    id: tema

    property string modo: "auto"        // "claro" | "oscuro" | "auto"
    // Minutos desde la medianoche; Para ti los actualiza con los de tu ciudad
    property int amanecer: 7 * 60
    property int atardecer: 19 * 60
    property int ahora: minutos()

    readonly property bool oscuro: modo === "oscuro" || (modo === "auto" && (ahora < amanecer || ahora >= atardecer))

    readonly property color texto: oscuro ? "#F5F5F7" : "#1D1D1F"
    readonly property color textoSuave: oscuro ? "#A1A1AA" : "#6E6E73"
    readonly property color icono: oscuro ? "#E5E5EA" : "#3A3D42"
    readonly property color repisa: oscuro ? "#24FFFFFF" : "#80FFFFFF"
    readonly property color repisaBorde: oscuro ? "#30FFFFFF" : "#CCFFFFFF"
    readonly property color sombra: oscuro ? "#70000000" : "#2A1E1440"
    readonly property color pastilla: oscuro ? "#3A3A46" : "#FFFFFF"     // pestaña activa, botones, menú
    readonly property color tarjeta: oscuro ? "#2C2C36" : "#FFFFFF"      // tiles sin imagen (lápiz)
    readonly property color esqueleto: oscuro ? "#2E2E38" : "#DADDE2"
    readonly property color esqueletoSuave: oscuro ? "#272730" : "#D8DBE0"
    readonly property color velo: oscuro ? "#66000000" : "#40000000"     // detrás del menú
    readonly property string fondo: "file:///var/lib/webosbrew/fullhomecustom/" + (oscuro ? "fondo-aurora.jpg" : "fondo.jpg")

    function minutos() {
        var d = new Date();
        return d.getHours() * 60 + d.getMinutes();
    }

    // "2026-10-22T07:12" → 432
    function horaEnMinutos(iso) {
        var m = /T(\d\d):(\d\d)/.exec(iso || "");
        return m ? parseInt(m[1], 10) * 60 + parseInt(m[2], 10) : -1;
    }

    function ponerSol(amanecerIso, atardecerIso) {
        var a = horaEnMinutos(amanecerIso), b = horaEnMinutos(atardecerIso);
        if (a >= 0 && b > a) {
            amanecer = a;
            atardecer = b;
        }
    }

    function db() {
        return LocalStorage.openDatabaseSync("lglow", "1.0", "Preferencias de LGlow", 1000);
    }

    function cargar() {
        try {
            db().transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS prefs(k TEXT PRIMARY KEY, v TEXT)");
                var r = tx.executeSql("SELECT v FROM prefs WHERE k = 'tema'");
                if (r.rows.length > 0)
                    tema.modo = r.rows.item(0).v;
            });
        } catch (e) {
            console.log("[lglow] no se pudo leer el tema: " + e);
        }
    }

    function elegir(m) {
        modo = m;
        try {
            db().transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS prefs(k TEXT PRIMARY KEY, v TEXT)");
                tx.executeSql("INSERT OR REPLACE INTO prefs(k, v) VALUES('tema', ?)", [m]);
            });
        } catch (e) {
            console.log("[lglow] no se pudo guardar el tema: " + e);
        }
    }

    // En automático, revisa la hora cada minuto
    property Timer reloj: Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: tema.ahora = tema.minutos()
    }

    Component.onCompleted: cargar()
}
