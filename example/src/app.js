const {ui} = require('tabris');

let scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, right: 0, top: 0, bottom: 0,
}).appendTo(ui.contentView);

scanner.start();
