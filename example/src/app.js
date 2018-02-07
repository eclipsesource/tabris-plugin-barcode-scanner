const {ui, Composite, CheckBox, Button, Picker, TextView} = require('tabris');

const BARCODES = ['code128', 'code39', 'code93', 'codabar', 'dataMatrix', 'ean13', 'ean8', 'itf', 'qrCode', 'upcA',
  'upcE', 'pdf417', 'aztec'];

let scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, right: 0, top: 0, bottom: '#controls',
}).on('detect', (event) => {
  console.log(`Barcode detected: ${event.format} ${event.data}`)
  barcode.text = event.format + '\n' + event.data;
})
  .appendTo(ui.contentView);

scanner.start();

let controls = new Composite({
  id: 'controls',
  left: 0, right: 0, bottom: 0, height: tabris.device.platform === 'iOS' ? 204 : undefined,
  background: 'white',
  padding: {left: 16, right: 16, top: 16, bottom: 24},
  elevation: 8
}).appendTo(ui.contentView);

let barcode = new TextView({
  left: 0, right: 0, top: 0,
  text: '<scan barcode>',
  alignment: 'center'
}).appendTo(controls);

new Picker({
  left: 0, right: 0, top: 'prev()',
  itemCount: BARCODES.length,
  itemText: (index) => BARCODES[index],
}).appendTo(controls);

new Button({
  left: 0, right: 0, top: 'prev()',
  text: 'Start'
}).appendTo(controls);
