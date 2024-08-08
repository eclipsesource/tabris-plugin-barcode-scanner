const {ui, Composite, Button, Picker, TextView, device} = require('tabris');

const is_iOS = device.platform === 'iOS';
const BARCODES = ['all formats', 'upcA', 'upcE', 'code39', 'code39Mod43', 'code93', 'code128',
  'ean8', 'ean13', 'pdf417', 'qr', 'aztec', 'interleaved2of5', 'itf', 'dataMatrix', 'codabar'];
const SCALE_MODES = ['fit', 'fill'];

let scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, right: 0, top: 0, bottom: '#controls',
}).on('detect', (event) => {
  barcodeTextView.text = `<b>${event.format}</b><br /><i>${event.data}</i>`;
  barcodeTextView.background = '#66BB6A';
  setTimeout(() => barcodeTextView.background = 'white', 500);
}).on('activeChanged', ({value: active}) => {
  scannerButton.text = (active ? 'Stop' : 'Start') + ' barcode scanner';
  formatPicker.enabled = !active;
}).on('error', (event) => console.log(event.error))
  .appendTo(ui.contentView);

const controls = new Composite({
  id: 'controls',
  left: 0, right: 0, bottom: 0,
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

new Picker({
  left: 16, right: 16, top: 'prev() 16',
  itemCount: SCALE_MODES.length,
  itemText: (index) => SCALE_MODES[index],
}).on('select', (event) => scanner.scaleMode = SCALE_MODES[event.index])
  .appendTo(controls);

let scannerButton = new Button({
  left: 16, right: 16, top: 'prev() 16',
  text: 'Start barcode scanner'
}).on('select', () => toggleScanner())
  .appendTo(controls);

if (is_iOS) {
  console.log(`Combinations available on this device, with camera: ${scanner.camera}.\n${JSON.stringify(tabris.ui.contentView.children()[0].frameDurationsForResolutions,null,2)}`);
  initIOSPickers();
}

function handleDetection(event) {
  barcodeTextView.text = `<b>${event.format}</b><br /><i>${event.data}</i>`;
  barcodeTextView.background = '#66BB6A';
  setTimeout(() => barcodeTextView.background = 'white', 500);
}

function handleActiveChange({ value: active }) {
  scannerButton.text = (active ? 'Stop' : 'Start') + ' barcode scanner';
  formatPicker.enabled = !active;
}

function handleError(event) {
  console.log(event.error);
}

function reloadIOSPickers() {
  const resolution = scanner.resolution;
  const frameDuration = scanner.frameDuration;

  const resolutionPicker = tabris.ui.contentView.find('#resolutionPicker')[0];
  const frameDurationPicker = tabris.ui.contentView.find('#frameDurationPicker')[0];

  const availableFrameDurations = scanner.availableFrameDurations;
  frameDurationPicker.itemCount = availableFrameDurations.length;

  const resolutionIndex = scanner.availableResolutions.findIndex(res => res.width === resolution.width && res.height === resolution.height);
  const frameDurationIndex = availableFrameDurations.findIndex(rate => rate === frameDuration);

  resolutionPicker.selectionIndex = resolutionIndex;
  frameDurationPicker.itemText = index => JSON.stringify(availableFrameDurations[index]);
  frameDurationPicker.selectionIndex = frameDurationIndex;
}

function toggleScanner() {
  if (scanner.active) {
    scanner.stop();
  } else {
    let index = formatPicker.selectionIndex;
    scanner.start(index !== 0 ? [BARCODES[index]] : []);
    if (is_iOS) reloadIOSPickers();
  }
}

function initIOSPickers() {
  const resolutionPicker = new Picker({
    id: 'resolutionPicker',
    left: 16, top: 'prev() 16', right: 16,
    itemCount: scanner.availableResolutions.length,
    selectionIndex: 0,
    itemText: index => JSON.stringify(scanner.availableResolutions[index]),
  }).on('select', handleResolutionSelect)
    .appendTo(controls);

  const frameDurationPicker = new Picker({
    id: 'frameDurationPicker',
    left: 16, top: 'prev() 16', right: 16,
    itemCount: scanner.availableFrameDurations.length,
    selectionIndex: 0,
    itemText: index => JSON.stringify(scanner.availableFrameDurations[index]),
  }).on('select', handleFrameDurationSelect)
    .appendTo(controls);
}

function handleResolutionSelect(e) {
  scanner.resolution = scanner.availableResolutions[e.index];
  reloadIOSPickers();
}

function handleFrameDurationSelect(e) {
  scanner.frameDuration = scanner.availableFrameDurations[e.index];
  reloadIOSPickers();
}

toggleScanner();
