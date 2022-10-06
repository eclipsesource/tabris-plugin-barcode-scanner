const { Composite, TextView, Picker, Button, contentView } = require('tabris');

const BARCODES = ['all formats', 'upcA', 'upcE', 'code39', 'code39Mod43', 'code93', 'code128',
  'ean8', 'ean13', 'pdf417', 'qr', 'aztec', 'interleaved2of5', 'itf', 'dataMatrix', 'codabar'];
const SCALE_MODES = ['fit', 'fill'];

let scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, top: 0, right: 0, bottom: '#controls',
}).on('detect', (event) => {
  barcodeTextView.text = `<b>${event.format}</b><br /><i>${event.data}</i>`;
  barcodeTextView.background = '#66BB6A';
  setTimeout(() => barcodeTextView.background = 'white', 500);
}).on('activeChanged', ({ value: active }) => {
  scannerButton.text = (active ? 'Stop' : 'Start') + ' barcode scanner';
  formatPicker.enabled = !active;
}).on('error', (event) => console.log(event.error))
  .appendTo(contentView);

let controls = new Composite({
  id: 'controls',
  left: 0, right: 0, bottom: 0,
  elevation: 2,
  background: '#FAFAFA',
}).appendTo(contentView);

let barcodeTextView = new TextView({
  left: 0, top: 0, right: 0, height: 48,
  text: '<i>Scanning for barcode...</i>',
  markupEnabled: true,
  lineSpacing: 1.2,
  font: '16px',
  alignment: 'centerX',
}).appendTo(controls);

new Composite({
  top: "prev()", left: 0, right: 0, height: 1,
  background: '#00000022',
}).appendTo(controls);

let formatPicker = new Picker({
  left: 16, top: 'prev() 16', right: 16,
  itemCount: BARCODES.length,
  selectionIndex: 0,
  itemText: (index) => BARCODES[index],
}).appendTo(controls);

new Picker({
  left: 16, top: 'prev() 16', right: 16,
  itemCount: SCALE_MODES.length,
  selectionIndex: 0,
  itemText: (index) => SCALE_MODES[index],
}).onSelect((event) => scanner.scaleMode = SCALE_MODES[event.index])
  .appendTo(controls);

let scannerButton = new Button({
  left: 16, top: 'prev() 16', right: 16, bottom: 24
}).onSelect(() => toggleScanner())
  .appendTo(controls);

function toggleScanner() {
  if (scanner.active) {
    scanner.stop();
  } else {
    let index = Math.max(0, formatPicker.selectionIndex);
    scanner.start(index !== 0 ? [BARCODES[index]] : []);
  }
}

toggleScanner();
