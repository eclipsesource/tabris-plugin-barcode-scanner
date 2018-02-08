const {ui, Composite, Button, Picker, TextView} = require('tabris');

const BARCODES = ['all formats', 'upcA', 'upcE', 'code39', 'code39Mod43', 'code93', 'code128', 'ean8', 'ean13', 'pdf417',
  'qr', 'aztec', 'interleaved2of5', 'itf', 'dataMatrix', 'codabar'];

let scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, right: 0, top: 0, bottom: '#controls',
}).on('detect', (event) => {
  barcodeTextView.text = `<b>${event.format}</b><br /><i>${event.data}</i>`;
  barcodeTextView.background = '#66BB6A';
  setTimeout(() => barcodeTextView.background = 'white', 500);
}).on('runningChanged', ({value: running}) => {
  scannerButton.text = (running ? 'Stop' : 'Start') + ' barcode scanner';
  formatPicker.enabled = !running;
}).on('error', (event) => console.log(event.error))
  .appendTo(ui.contentView);

let controls = new Composite({
  id: 'controls',
  left: 0, right: 0, bottom: 0, height: tabris.device.platform === 'iOS' ? 204 : undefined,
  background: '#FAFAFA',
}).appendTo(ui.contentView);

let barcodeTextView = new TextView({
  left: 0, right: 0, top: 0, height: 64,
  text: '<i><b>Waiting for barcode...</b></i>',
  markupEnabled: true,
  lineSpacing: 1.2,
  font: '16px',
  alignment: 'center',
  background: 'white',
  elevation: 2
}).appendTo(controls);

let formatPicker = new Picker({
  left: 16, right: 16, top: 'prev() 16',
  itemCount: BARCODES.length,
  itemText: (index) => BARCODES[index],
}).appendTo(controls);

let scannerButton = new Button({
  left: 16, right: 16, top: 'prev() 16', bottom: 24
}).on('select', () => toggleScanner())
  .appendTo(controls);

function toggleScanner() {
  if (scanner.running) {
    scanner.stop();
  } else {
    let index = formatPicker.selectionIndex;
    scanner.start(index !== 0 ? [BARCODES[index]] : []);
  }
}

toggleScanner();
