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
    super._dispose();
  }

  start(formats = []) {
    if (this.active) {
      throw new Error('BarcodeScanner is already active');
    }
    this._nativeCall('start', { formats });
    this._storeProperty('active', true);
  }

  stop() {
    this._nativeCall('stop');
    this._storeProperty('active', false);
  }
}

tabris.NativeObject.defineProperties(BarcodeScannerView.prototype, {
  camera: {
    type: 'string',
    choice: ['front', 'back'],
    default: 'back'
  },
  scaleMode: {
    type: 'string',
    choice: ['fit', 'fill'],
    default: 'fit'
  },
  active: {
    type: 'boolean',
    readonly: true
  }
});

if (device.platform === 'iOS') {
  tabris.NativeObject.defineProperties(BarcodeScannerView.prototype, {

    // `frameDurationsForResolutions` will change depending on the value of
    // the `camera` property; otherwise, it's constant.

    // Changing the `camera` property (front/back) will change
    // `availableResolutions`!

    // Setting an unsupported `resolution` or `frameDuration` value will
    // result in an exception being thrown!

    // Changing `resolution` will change `availableFrameDurations`!

    // On iOS, different frameDurations are available for each resolution.
    // When modifying the `resolution` property, the `frameDuration` will most
    // likely change too!

    frameDurationsForResolutions: {
      type: 'any',
      nocache: true,
    },
    resolution: {
      type: 'any',
      nocache: true,
    },
    availableResolutions: {
      type: 'any',
      nocache: true,
    },
    frameDuration: {
      type: 'any',
      nocache: true,
    },
    availableFrameDurations: {
      type: 'any',
      nocache: true,
    },
  });
}

module.exports = BarcodeScannerView;
