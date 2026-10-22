// Simula teclas del control remoto: node key.js HOME DOWN ENTER ...
// Escribe eventos de teclado directo en el dispositivo del control IR (LGE RCU),
// igual que si se presionara el botón físico. Un número se toma como código crudo.
var fs = require('fs');

var DEV = process.env.KEY_DEV || '/dev/input/event1';
var CODES = {
    HOME: 125, BACK: 14, EXIT: 174, ENTER: 28, OK: 28,
    UP: 103, DOWN: 108, LEFT: 105, RIGHT: 106,
    MENU: 139, SETTINGS: 139, INFO: 358
};

function ev(fd, type, code, value) {
    // struct input_event en ARM 32 bits: timeval(8) type(2) code(2) value(4)
    var b = new Buffer(16);
    b.fill(0);
    var now = Date.now();
    b.writeInt32LE(Math.floor(now / 1000), 0);
    b.writeInt32LE((now % 1000) * 1000, 4);
    b.writeUInt16LE(type, 8);
    b.writeUInt16LE(code, 10);
    b.writeInt32LE(value, 12);
    fs.writeSync(fd, b, 0, 16);
}

var fd = fs.openSync(DEV, 'w');
var keys = process.argv.slice(2);
var i = 0;
function next() {
    if (i >= keys.length) { fs.closeSync(fd); return; }
    var k = keys[i++];
    var code = /^\d+$/.test(k) ? parseInt(k, 10) : CODES[k.toUpperCase()];
    if (code === undefined) { console.log('Tecla desconocida: ' + k); return next(); }
    ev(fd, 1, code, 1); ev(fd, 0, 0, 0);
    setTimeout(function () {
        ev(fd, 1, code, 0); ev(fd, 0, 0, 0);
        setTimeout(next, 600);
    }, 80);
}
next();
