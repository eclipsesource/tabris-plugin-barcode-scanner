const EVENT_TYPES = ['detect', 'error'];

class BarcodeScannerView extends tabris.Widget {

  get _nativeType() {
    return 'com.eclipsesource.barcodescanner.BarcodeScannerView';
  }

  _listen(name, listening) {
    if (EVENT_TYPES.includes(name)) {
      this._nativeListen(name, listening);
    } else {
      super._listen(name, listening);
    }
  }

  start(formats = []) {
    if (this.running) {
      throw new Error('BarcodeScanner is already running')
    }
    this.running = true;
    this._nativeCall('start', {formats});
  }

  stop() {
    this._nativeCall('stop');
  }

}

tabris.NativeObject.defineProperties(BarcodeScannerView.prototype, {
  'camera': {
    type: ['choice', ['front', 'back']],
    default: 'back'
  }
});

module.exports = BarcodeScannerView;
