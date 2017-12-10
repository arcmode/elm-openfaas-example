"use strict"

global.XMLHttpRequest = require('xhr2');
const {stdin, stdout} = process;
stdin.setEncoding('utf8');

const handler = require('./function/handler');
const ports = handler.Main.worker().ports;

stdin.on('readable', () => {
	  let chunk;

    // TTY ?
    while ((chunk = stdin.read())) {
        {
            const handleOutput = function (payload) {
                ports.output.unsubscribe(handleOutput);
                console.log(payload);
            }
            ports.output.subscribe(handleOutput);
            ports.input.send(chunk);
        };
    }
});
