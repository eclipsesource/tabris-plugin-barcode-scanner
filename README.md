# Tabris.js Barcode Scanner Plugin

A barcode scanner widget for [Tabris.js](https://tabrisjs.com), allowing to scan various types of barcodes.

## Example

The following snippet shows how the `tabris-plugin-barcode-scanner` plugin can be used in a Tabris.js app:

```javascript
let scanner = new esbarcodescanner.BarcodeScannerView({camera: 'back'})
  .on('detect', (e) => console.log(`Detected ${e.format} code with data ${e.data}`))
  .on('error', (e) => console.log(e.error))
  .appendTo(comp);
scanner.start({format: 'qrCode'});
```
A more elaborate example can be found in the [example](example/) folder. It provides a Tabris.js project that demonstrates the various features of the `tabris-plugin-barcode-scanner` widget. Consult the [README](example/README.md) of the example for build instructions.

## Integrating the plugin
The Tabris.js website provides detailed information on how to [integrate custom widgets](https://tabrisjs.com/documentation/latest/build#adding-plugins) in your Tabris.js app. To add the plugin to your app add the following entry in your apps `config.xml`:

```xml
<plugin name="tabris-plugin-barcode-scanner" spec="^1.0.0" />
```

To fetch the latest development version use the GitHub URL:

```xml
<plugin name="tabris-plugin-barcode-scanner" spec="https://github.com/eclipsesource/tabris-plugin-barcode-scanner.git" />
```

## API

The wiget api consists of the object `esbarcodescanner.BarcodeScannerView` with the following properties and events.

### Properties

The following properties can be applied on top of the [common Tabris.js widget properties](https://tabrisjs.com/documentation/latest/api/Widget#properties):

* `camera` : _string_, supported values: `front`, `back`, default: `back`
  * The camera to use when scanning for barcodes. Has to be set in the constructor of the `BarcodeScannerView`. 

### Events

#### detect

Fired when a barcode has been detected.

##### Event parameter
* `format`: _string_
  * The format of the detected barcode
* `data`: _string_
  * The data contained in the barcode

#### error

Fired when an error during the `BarcodeScannerView`s lifecycle happened. After an an error occured no further `detect` event will be fired.

##### Event parameter
* `error`: _string_
  * Details about the error

### Functions

#### `start([format])`

Enables the camera and starts scanning for barcodes. The given `format` can be used narrow down the detected barcodes.

Example:
```js
scanner.start({format: ['qrCode']});
```

##### Parameter

* `format` : _string[]_
  * The optional format allows to limit the detection of barcodes to only the given formats. If omitted all supported barcodes will be detected.
  
#### `stop()`

Stops the barcode scanning and disables the camera.

Example:
```js
scanner.stop();
```

## Compatibility
  
Compatible with [Tabris.js 2.3.0](https://github.com/eclipsesource/tabris-js/releases/tag/v2.3.0)

### Supported platforms

 * Android

## Development of the widget

While not required by the consumer or the widget, this repository provides a `project` folder that contains platform specific development artifacts. These artifacts allow to more easily consume the native source code when developing the native parts of the widget.

### Android

The project provides a gradle based build configuration, which also allows to import the project into Android Studio.

In order to reference the Tabris.js specific APIs, the environment variable `TABRIS_ANDROID_PLATFORM` has to point to the Tabris.js Android Cordova platform root directory.

```bash
export TABRIS_ANDROID_PLATFORM=/home/user/tabris-android-cordova
```
 The environment variable is consumed in the gradle projects [build.gradle](project/android/build.gradle) file.

## Copyright

 See [LICENSE](LICENSE) notice.
