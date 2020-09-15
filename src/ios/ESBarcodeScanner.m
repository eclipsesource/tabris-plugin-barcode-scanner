//
//  ESBarcodeScanner.m
//  tabris-plugin-barcode-scanner
//
//  Created by Patryk Mól on 06.02.2018.
//  Copyright (c) 2018 EclipseSource. All rights reserved.
//

#import "ESBarcodeScanner.h"
#import "ESScannerView.h"

@interface ESBarcodeScanner () <AVCaptureMetadataOutputObjectsDelegate>
@property (strong, nonatomic) ESScannerView *scanner;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) NSString *lastData;
@property (strong, nonatomic) NSString *lastFormat;
@property (assign, nonatomic) NSTimeInterval lastSent;
@end

@implementation ESBarcodeScanner

- (instancetype)initWithObjectId:(NSString *)objectId properties:(NSDictionary *)properties inContext:(id<TabrisContext>)context {
    self = [super initWithObjectId:objectId properties:properties inContext:context];
    if (self) {
        self.scanner = [ESScannerView new];
        [self registerSelector:@selector(start:) forCall:@"start"];
        [self registerSelector:@selector(stop) forCall:@"stop"];
        [self defineWidgetView:self.scanner];
        NSString *camera = [properties objectForKey:@"camera"];
        if (camera) {
            self.camera = camera;
        } else {
            self.camera = @"back";
        }
        NSString *scaleMode = [properties objectForKey:@"scaleMode"];
        if (scaleMode) {
            self.scaleMode = scaleMode;
        } else {
            self.scaleMode = @"fit";
        }
    }
    return self;
}

+ (NSString *)remoteObjectType {
    return @"com.eclipsesource.barcodescanner.BarcodeScannerView";
}

+ (NSMutableSet *)clientObjectProperties {
    NSMutableSet *set = [super remoteObjectProperties];
    [set addObject:@"camera"];
    [set addObject:@"scaleMode"];
    return set;
}

- (UIView *)viewForEmbedding {
    return self.scanner;
}

- (void)setScaleMode:(NSString *)scaleMode {
    _scaleMode = scaleMode;
    self.scanner.scaleMode = scaleMode;
}

- (void)start:(NSDictionary *)properties {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        if (!self.session) {
            [self initializeSession];
        }
        if (self.session) {
            [self setFormats:[properties objectForKey:@"formats"]];
            [self.scanner addSession:self.session];
            [self.session startRunning];
        }
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        NSString *description = (status == AVAuthorizationStatusDenied) ? @"Camera permission not granted" : @"Camera access restricted";
        [self sendError:description];
    } else {
        __weak ESBarcodeScanner *weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            __strong ESBarcodeScanner *strongSelf = weakSelf;
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf start:properties];
                });
            } else {
                [strongSelf sendError:@"Camera permission not granted"];
            }
        }];
    }
}

- (void)stop {
    [self.session stopRunning];
}

- (void)initializeSession {
    self.session = [[AVCaptureSession alloc] init];
    self.device = [self getCaptureDevice];
    NSError *error = nil;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (self.input) {
        [self.session addInput:self.input];
    } else {
        [self sendError:@"Could not initialize camera"];
        return;
    }
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:self.output];
}

- (void)setFormats:(NSArray *)formats {
    if (formats.count == 0) {
        self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    } else {
        NSMutableArray *allowedFormats = [[NSMutableArray alloc] initWithCapacity:formats.count];
        for (NSString *format in formats) {
            if ([format isEqualToString:@"upcA"]) {
                [allowedFormats addObject:AVMetadataObjectTypeEAN13Code];
            } else if ([format isEqualToString:@"upcE"]) {
                [allowedFormats addObject:AVMetadataObjectTypeUPCECode];
            } else if ([format isEqualToString:@"code39"]) {
                [allowedFormats addObject:AVMetadataObjectTypeCode39Code];
            } else if ([format isEqualToString:@"code39Mod43"]) {
                [allowedFormats addObject:AVMetadataObjectTypeCode39Mod43Code];
            } else if ([format isEqualToString:@"code93"]) {
                [allowedFormats addObject:AVMetadataObjectTypeCode93Code];
            } else if ([format isEqualToString:@"code128"]) {
                [allowedFormats addObject:AVMetadataObjectTypeCode128Code];
            } else if ([format isEqualToString:@"ean8"]) {
                [allowedFormats addObject:AVMetadataObjectTypeEAN8Code];
            } else if ([format isEqualToString:@"ean13"]) {
                [allowedFormats addObject:AVMetadataObjectTypeEAN13Code];
            } else if ([format isEqualToString:@"pdf417"]) {
                [allowedFormats addObject:AVMetadataObjectTypePDF417Code];
            } else if ([format isEqualToString:@"qr"]) {
                [allowedFormats addObject:AVMetadataObjectTypeQRCode];
            } else if ([format isEqualToString:@"aztec"]) {
                [allowedFormats addObject:AVMetadataObjectTypeAztecCode];
            } else if ([format isEqualToString:@"interleaved2of5"]) {
                [allowedFormats addObject:AVMetadataObjectTypeInterleaved2of5Code];
            } else if ([format isEqualToString:@"itf"]) {
                [allowedFormats addObject:AVMetadataObjectTypeITF14Code];
            } else if ([format isEqualToString:@"dataMatrix"]) {
                [allowedFormats addObject:AVMetadataObjectTypeDataMatrixCode];
            }
        }
        self.output.metadataObjectTypes = allowedFormats;
    }
}

- (AVCaptureDevice *)getCaptureDevice {
    if ([self.camera isEqualToString:@"front"]) {
        return [self frontCamera];
    } else if ([self.camera isEqualToString:@"back"]) {
        return [self rearCamera];
    }
    return [self rearCamera];
}


- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return [self rearCamera];
}

- (AVCaptureDevice *)rearCamera {
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)sendDetect:(NSString *)data format:(NSString *)format {
    if (self.detectListener && format && data) {
        [self fireEventNamed:@"detect" withAttributes:@{@"format":format, @"data":data}];
    }
}

- (void)sendError:(NSString *)error {
    if (self.errorListener) {
        [self fireEventNamed:@"error" withAttributes:@{@"error":error ?: [NSNull null]}];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            NSString *data = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            NSString *format = metadata.type;

            if (!data || !format) {
                continue;
            }

            if (![format isEqualToString:self.lastFormat] || ![data isEqualToString:self.lastData] || [[NSDate date] timeIntervalSince1970] - self.lastSent > 1) {
                [self sendDetect:data format:format];
                self.lastData = data;
                self.lastFormat = format;
                self.lastSent = [[NSDate date] timeIntervalSince1970];
            }
        }
    }
}

@end
