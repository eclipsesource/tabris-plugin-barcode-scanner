const EVENT_TYPES = ['detect', 'error'];

class BarcodeScannerView extends tabris.Widget {

  constructor(properties) {
    super(properties);
  }

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

  _trigger(name, event) {
    if (name === 'error') {
      this.stop();
    }
    return super._trigger(name, event);
  }

  _dispose() {
    this.stop();
  }

  start(formats = []) {
    if (this.running) {
      throw new Error('BarcodeScanner is already running')
    }
    this._nativeCall('start', {formats});
    this._storeProperty('running', true);
  }

  stop() {
    this._nativeCall('stop');
    this._storeProperty('running', false);
  }

}

tabris.NativeObject.defineProperties(BarcodeScannerView.prototype, {
  'camera': {
    type: ['choice', ['front', 'back']],
    default: 'back'
  },
  'scaleMode': {
    type: ['choice', ['fit', 'fill']],
    default: 'fit'
  },
  'running': {
    type: 'boolean',
    readonly: true
  },
});

module.exports = BarcodeScannerView;
