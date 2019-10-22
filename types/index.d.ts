import { EventObject, JSXAttributes, Properties, PropertyChangedEvent, Widget } from 'tabris';
/// <reference path='../../node_modules/tabris/tabris.d.ts' />

interface BarcodeScannerViewProperties {
  camera?: 'front' | 'back';
  scaleMode?: 'fit' | 'fill';
  readonly active?: boolean;
}

interface BarcodeScannerViewEvents {
  detect?: (event: DetectEvent) => void;
  error?: (event: ErrorEvent) => void;
    activeChanged?: (event: ActiveChangedEvent) => void;
}

declare global {
  namespace esbarcodescanner {
    interface BarcodeScannerView extends BarcodeScannerViewProperties {}
    class BarcodeScannerView extends Widget {
      public jsxAttributes: JSXAttributes<this> & BarcodeScannerViewProperties & {
        onDetect?: (event: DetectEvent) => void,
        onError?: (event: ErrorEvent) => void,
        onActiveChanged?: (event: ActiveChangedEvent) => void
      };
      constructor(properties: Properties<Widget> & BarcodeScannerViewProperties);
      start(formats: BarcodeScannerFormat[]): void;
      stop(): void;
      on(type: string, listener: (event: any) => void, context?: object): this;
      on(listeners: BarcodeScannerViewEvents): this;
      off(type: string, listener: (event: any) => void, context?: object): this;
      off(listeners: BarcodeScannerViewEvents): this;
      once(type: string, listener: (event: any) => void, context?: object): this;
      once(listeners: BarcodeScannerViewEvents): this;
    }
  }
}

type BarcodeScannerFormat =
  'upcA' |
  'upcE' |
  'code39' |
  'code39Mod43' |
  'code93' |
  'code128' |
  'ean8' |
  'ean13' |
  'pdf417' |
  'qr' |
  'aztec' |
  'interleaved2of5' |
  'itf' |
  'dataMatrix' |
  'codabar';

interface ErrorEvent extends EventObject<esbarcodescanner.BarcodeScannerView> {
  error: string;
}

interface DetectEvent extends EventObject<esbarcodescanner.BarcodeScannerView> {
  format: BarcodeScannerFormat;
  data: string;
}

type ActiveChangedEvent = PropertyChangedEvent<esbarcodescanner.BarcodeScannerView, boolean>;
