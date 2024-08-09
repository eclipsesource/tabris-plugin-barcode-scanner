const { Composite, TextView, Picker, Button, contentView, device } = require('tabris');

const is_iOS = device.platform === 'iOS';
const BARCODES = ['all formats', 'upcA', 'upcE', 'code39', 'code39Mod43', 'code93', 'code128',
  'ean8', 'ean13', 'pdf417', 'qr', 'aztec', 'interleaved2of5', 'itf', 'dataMatrix', 'codabar'];
const SCALE_MODES = ['fit', 'fill'];

const scanner = new esbarcodescanner.BarcodeScannerView({
  left: 0, top: 0, right: 0, bottom: '#controls',
}).on('detect', handleDetection)
  .on('activeChanged', handleActiveChange)
  .on('error', handleError)
  .appendTo(contentView);

const controls = new Composite({
  id: 'controls',
  left: 0, right: 0, bottom: 0,
  elevation: 2,
  background: '#FAFAFA',
}).appendTo(contentView);

const barcodeTextView = new TextView({
  left: 0, top: 0, right: 0, height: 48,
  text: '<i>Scanning for barcode...</i>',
  markupEnabled: true,
  lineSpacing: 1.2,
  font: '16px',
  alignment: 'centerX',
}).appendTo(controls);

new Composite({
  top: 'prev()', left: 0, right: 0, height: 1,
  background: '#00000022',
}).appendTo(controls);

const formatPicker = new Picker({
  left: 16, top: 'prev() 16', right: 16,
  itemCount: BARCODES.length,
  selectionIndex: 0,
  itemText: index => BARCODES[index],
}).appendTo(controls);

new Picker({
  left: 16, top: 'prev() 16', right: 16,
  itemCount: SCALE_MODES.length,
  selectionIndex: 0,
  itemText: index => SCALE_MODES[index],
}).onSelect(event => scanner.scaleMode = SCALE_MODES[event.index])
  .appendTo(controls);

if (is_iOS) {
  console.log(`Combinations available on this device, with camera: ${scanner.camera}.\n${JSON.stringify(tabris.contentView.children()[0].frameDurationsForResolutions,null,2)}`);
  initIOSPickers();
}

const scannerButton = new Button({
  left: 16, top: 'prev() 16', right: 16, bottom: 24
}).onSelect(toggleScanner)
  .appendTo(controls);

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

function toggleScanner() {
  if (scanner.active) {
    scanner.stop();
  } else {
    const index = Math.max(0, formatPicker.selectionIndex);
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
  }).onSelect(handleResolutionSelect)
    .appendTo(controls);

  const frameDurationPicker = new Picker({
    id: 'frameDurationPicker',
    left: 16, top: 'prev() 16', right: 16,
    itemCount: scanner.availableFrameDurations.length,
    selectionIndex: 0,
    itemText: index => JSON.stringify(scanner.availableFrameDurations[index]),
  }).onSelect(handleFrameDurationSelect)
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

function reloadIOSPickers() {
  const resolution = scanner.resolution;
  const frameDuration = scanner.frameDuration;

  const resolutionPicker = $(Picker).first('#resolutionPicker');
  const frameDurationPicker = $(Picker).first('#frameDurationPicker');

  const availableFrameDurations = scanner.availableFrameDurations;
  frameDurationPicker.itemCount = availableFrameDurations.length;

  const resolutionIndex = scanner.availableResolutions.findIndex(res => res.width === resolution.width && res.height === resolution.height);
  const frameDurationIndex = availableFrameDurations.findIndex(rate => rate === frameDuration);

  resolutionPicker.selectionIndex = resolutionIndex;
  frameDurationPicker.itemText = index => JSON.stringify(availableFrameDurations[index]);
  frameDurationPicker.selectionIndex = frameDurationIndex;
}

toggleScanner();
