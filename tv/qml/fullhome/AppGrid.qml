import QtQuick 2.6
import QtGraphicalEffects 1.0

// [fullhome-custom] Apps estilo Free My TV, con tiles grandes 5:3. Dos modos:
//   - "pinned" (home): una fila con las apps fijadas (las primeras 6 en el orden de LG).
//     ↓ desde ella baja a todas las apps (señal openAll).
//   - "all" (parte de abajo del home): todas las apps (4 filas visibles, se desliza si hay
//     más) y el lápiz al final para reordenar. Atrás, o ↑ desde la primera fila, regresa
//     (señal closeAll).
// Usa el mismo modelo y la misma forma de lanzar apps que la fila original de LG (que
// sigue cargada, oculta, y se muestra en el modo edición).
FocusScope {

    id: root

    property int columns: 6
    property int tileW: styleSheet.getRValue(268)
    property int tileH: Math.round(tileW * 0.6)
    property int gap: styleSheet.getRValue(26)
    property var lpModel: interfaces.launchPoints.launchPointsModel

    property string mode: "pinned"
    // Mientras la pantalla "Apps" está abierta encima, la fila del home no reclama el foco
    property bool suspended: false
    readonly property bool isAll: mode === "all"
    readonly property int pinnedCount: columns
    readonly property int pinnedShown: Math.min(lpModel.count, pinnedCount)

    signal openAll()
    signal closeAll()
    // Lápiz: abre el modo edición de LG (reordenar = elegir cuáles van fijadas)
    property var editEntry: ({ "id": "edit", "launchPointId": "edit", "tileType": "edit", "title": "" })

    readonly property int cellCount: isAll ? lpModel.count + 1 : pinnedShown
    readonly property int rows: Math.ceil(cellCount / columns)
    property int visibleRows: isAll ? 4 : 1
    property int firstRow: 0
    readonly property int shownRows: Math.max(1, Math.min(rows, visibleRows))

    // Sube cuando cambia o se reordena el contenido del modelo (mismo count, otras apps)
    property int revision: 0

    width: columns * tileW + (columns - 1) * gap
    height: shownRows * tileH + (shownRows - 1) * gap

    Connections {
        target: root.lpModel
        onDataChanged: root.revision++
        onRowsMoved: root.revision++
        onRowsInserted: root.revision++
        onRowsRemoved: root.revision++
    }

    function entryAt(i) {
        return i < lpModel.count ? lpModel.get(i).entry : editEntry;
    }

    function focusLast() {
        grid.currentIndex = grid.count - 1;
    }

    function reset() {
        root.firstRow = 0;
        grid.currentIndex = 0;
    }

    // Entrada escalonada de los tiles (cada delegate escucha esta señal)
    signal intro()

    function isBackKey(key) {
        // Atrás del control llega como Key_webOS_Back; las otras por si acaso
        return key === uiController.webOS.Key_webOS_Back || key === Qt.Key_Back
            || key === Qt.Key_Escape || key === Qt.Key_Backspace;
    }

    function launch(i) {
        var obj = entryAt(i);
        if (!obj)
            return;
        if (obj.tileType === "edit") {
            // El modo edición de LG se dibuja en el home: primero cerrar la pantalla "Apps"
            // (que va encima de todo) para que no quede oculto debajo
            if (root.isAll)
                root.closeAll();
        } else {
            uiController.userLogger.appLaunched(obj.id, "launcher", i, systemProperties.home_type);
        }
        interfaces.launchPoints.doLaunch(obj);
    }

    // El foco puede perderse en dos casos, y en ambos lo reclamamos:
    //  - el home se precarga en segundo plano (preloadmanager) y luego se muestra: el foco
    //    se queda en appListArea sin bajar a la cuadrícula;
    //  - al abrir una app, MainView se vuelve invisible (visible: isAppForeground) y pierde
    //    el foco; al volver, Qt no lo regresa aquí. LG también vuelve a las apps al regresar.
    function claimFocus(force) {
        if (isAll || suspended || !visible || uiController.isEditMode || root.activeFocus)
            return;
        if (force || (parent && parent.activeFocus))
            root.forceActiveFocus();
    }

    onVisibleChanged: {
        if (visible)
            showTimer.restart();
    }

    Connections {
        target: root.parent
        onActiveFocusChanged: focusTimer.restart()
    }

    Connections {
        target: uiController
        onHomeShownChanged: {
            if (uiController.homeShown) {
                showTimer.restart();
                if (!root.isAll)
                    root.intro();
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 120
        onTriggered: root.claimFocus(false)
    }

    Timer {
        id: showTimer
        interval: 150
        onTriggered: root.claimFocus(true)
    }

    GridView {

        id: grid

        // El GridView cuenta cada columna con su espacio: le damos el ancho completo
        width: root.columns * cellWidth
        height: root.rows * cellHeight
        y: -root.firstRow * cellHeight
        cellWidth: root.tileW + root.gap
        cellHeight: root.tileH + root.gap
        model: root.cellCount
        focus: true
        interactive: false
        keyNavigationWraps: false
        highlightFollowsCurrentItem: false

        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        // Mantiene visible la fila del elemento con foco
        onCurrentIndexChanged: {
            var r = Math.floor(currentIndex / root.columns);
            if (r < root.firstRow)
                root.firstRow = r;
            else if (r >= root.firstRow + root.visibleRows)
                root.firstRow = r - root.visibleRows + 1;
        }

        // Navegación con el control: con interactive:false el GridView no la hace solo
        Keys.onPressed: {
            var c = root.columns, i = currentIndex, n = count;
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.launch(i);
                event.accepted = true;
                break;
            case Qt.Key_Right:
                if (i % c < c - 1 && i + 1 < n)
                    currentIndex = i + 1;
                event.accepted = true;
                break;
            case Qt.Key_Left:
                if (i % c > 0)
                    currentIndex = i - 1;
                event.accepted = true;
                break;
            case Qt.Key_Down:
                if (Math.floor(i / c) < root.rows - 1) {
                    currentIndex = Math.min(i + c, n - 1);
                    event.accepted = true;
                } else if (root.isAll) {
                    event.accepted = true; // en "todas" no baja más
                } else {
                    root.openAll(); // ↓ desde la fila del home abre la pantalla Apps
                    event.accepted = true;
                }
                break;
            case Qt.Key_Up:
                if (i >= c) {
                    currentIndex = i - c;
                    event.accepted = true;
                } else if (root.isAll) {
                    root.closeAll();
                    event.accepted = true;
                } else {
                    event.accepted = false; // sube a "Para ti" o a los íconos de arriba
                }
                break;
            default:
                // Atrás se atiende al soltar (abajo); aquí solo se consume la pulsación
                if (root.isAll && root.isBackKey(event.key))
                    event.accepted = true;
                break;
            }
        }

        // LG cierra el home al *soltar* Atrás (UIController.Keys.onReleased → goBack). Si
        // cerráramos al presionar, el soltar llegaría a LG y haría un segundo "atrás".
        Keys.onReleased: {
            if (root.isAll && root.isBackKey(event.key)) {
                root.closeAll();
                event.accepted = true;
            }
        }

        delegate: Item {

            id: cell

            property var obj: { root.revision; return root.entryAt(index); }
            property bool selected: GridView.isCurrentItem && root.activeFocus
            property bool isEdit: obj && obj.tileType === "edit"
            property int row: Math.floor(index / root.columns)
            property int col: index % root.columns
            // 0 → 1 en la entrada escalonada
            property real shown: 1
            readonly property color glowColor: cell.obj && cell.obj.iconColor && !cell.isEdit ? cell.obj.iconColor : "#FF4F8B"

            width: root.tileW
            height: root.tileH
            z: selected ? 2 : 1
            scale: selected ? 1.12 : 1
            // Solo se ven las filas dentro de la ventana visible
            opacity: row >= root.firstRow && row < root.firstRow + root.visibleRows ? 1 : 0
            enabled: opacity === 1

            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 160 } }

            Connections {
                target: root
                onIntro: {
                    // Solo las filas visibles; las demás ya quedan listas
                    if (cell.row < root.firstRow || cell.row >= root.firstRow + root.visibleRows) {
                        cell.shown = 1;
                        return;
                    }
                    cell.shown = 0;
                    introAnim.restart();
                }
            }

            SequentialAnimation {
                id: introAnim
                PauseAnimation { duration: 40 * cell.col + 70 * (cell.row - root.firstRow) }
                NumberAnimation { target: cell; property: "shown"; to: 1; duration: 320; easing.type: Easing.OutCubic }
            }

            // Brillo del color de la app detrás del tile con foco
            RectangularGlow {
                anchors.fill: parent
                glowRadius: styleSheet.getRValue(26)
                spread: 0.15
                cornerRadius: styleSheet.getRValue(22) + glowRadius
                color: cell.glowColor
                opacity: cell.selected ? 0.55 * cell.shown : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Item {

                id: face
                anchors.fill: parent
                opacity: cell.shown
                transform: Translate { y: (1 - cell.shown) * styleSheet.getRValue(28) }

                // Sombra suave del tile con foco
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: styleSheet.getRValue(14)
                    anchors.leftMargin: styleSheet.getRValue(6)
                    anchors.rightMargin: styleSheet.getRValue(6)
                    anchors.bottomMargin: -styleSheet.getRValue(10)
                    radius: styleSheet.getRValue(24)
                    color: "#38000000"
                    visible: cell.selected
                }

                // Respaldo para apps sin tile pre-renderado: color de la app + ícono
                Rectangle {
                    anchors.fill: parent
                    radius: styleSheet.getRValue(22)
                    color: cell.isEdit ? lglowTema.tarjeta : (cell.obj && cell.obj.iconColor ? cell.obj.iconColor : "#FFFFFF")
                    visible: tile.status !== Image.Ready
                }

                Image {
                    anchors.centerIn: parent
                    width: Math.round(root.tileH * 0.82)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    source: !cell.obj || cell.isEdit ? "" : (cell.obj.largeIcon || cell.obj.mediumLargeIcon || cell.obj.icon || "")
                    visible: !cell.isEdit && tile.status !== Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "✎"
                    color: lglowTema.icono
                    font.pixelSize: styleSheet.getRValue(64)
                    visible: cell.isEdit
                }

                // Tile pre-renderado (tools/make-tiles.py)
                Image {
                    id: tile
                    anchors.fill: parent
                    source: cell.obj && !cell.isEdit ? "file:///var/lib/webosbrew/fullhomecustom/tiles/" + cell.obj.id + ".png" : ""
                    sourceSize: Qt.size(300, 180)
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    grid.currentIndex = index;
                    root.forceActiveFocus();
                }
                onClicked: root.launch(index)
            }
        }
    }

    // Indicadores de más apps en la pantalla "Apps"
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: styleSheet.getRValue(2)
        text: "▾"
        color: "#8E8E93"
        font.pixelSize: styleSheet.getRValue(22)
        visible: root.isAll && root.firstRow + root.visibleRows < root.rows
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: styleSheet.getRValue(2)
        text: "▴"
        color: "#8E8E93"
        font.pixelSize: styleSheet.getRValue(22)
        visible: root.isAll && root.firstRow > 0
    }
}
