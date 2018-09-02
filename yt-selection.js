const result = JSON.parse(process.argv.slice(2).join(' '));

var fs = require('fs');
var blessed = require('blessed');
var program = blessed.program();
var selectedID = 0;

program.on('keypress', function(ch, key) {
  if (key.name === 'q') {
    program.clear();
    program.disableMouse();
    program.showCursor();
    program.normalBuffer();
    process.exit(0);
  } else if (key.name === 'up' ) {
    selectedID--;
    selectedID = Math.min(Math.max(selectedID, 0), listSize - 1);
  } else if (key.name === 'down' ) {
    selectedID++;
    selectedID = Math.min(Math.max(selectedID, 0), listSize - 1);
  } else if (key.name === 'enter' ) {
    program.clear();
    program.disableMouse();
    program.showCursor();
    program.normalBuffer();
    clearTimeout(loopId);
    fs.writeFileSync("tmp.txt", "" + result.items[selectedID].snippet.title + "\n" + result.items[selectedID].id.videoId + "\n");
    process.exit(0);
  }
});

program.alternateBuffer();
program.hideCursor();
program.clear();

let width, height, listSize = 10, loopId;

program.getWindowSize(function() {
  if (arguments[0]) {
    process.exit(0);
  }
  width = arguments[1].width;
  height = arguments[1].height;
  listSize = height - 2 ;
});

let previousID = null;
const loop = function (options) {
  if (width) {
    result.items.slice(0, listSize).forEach((item, i) => {
      if (selectedID === previousID || (i !== selectedID && i !== previousID && previousID !== null)) {
        return;
      }
      if (i === selectedID) {
        program.bg('red');
      } else {
        program.bg('black');
      }
      program.move(1, i + 1);
      program.write(item.snippet.title);
    });
    previousID = selectedID;
  }
  if (!width || !options.once) loopId = setTimeout(loop.bind(this, options), 16);
};
loop({once: false});
