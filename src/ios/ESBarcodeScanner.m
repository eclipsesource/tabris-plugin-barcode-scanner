//
//  ESBarcodeScanner.m
//  tabris-plugin-barcode-scanner
//
//  Created by Patryk Mól on 06.02.2018.
//  Updated by Karol Szafrański on 09.08.2024.
//  Copyright (c) 2018 EclipseSource. All rights reserved.
//

#import <Tabris/Tabris.h>
#import "ESBarcodeScanner.h"
#import "ESScannerView.h"
#import "BSCameraResolution.h"
#import "AVCaptureDeviceFormat+TabrisBarcodeScanner.h"

#define ESBarcodeScannerExceptionName @"ESBarcodeScannerException"

typedef NSMutableDictionary<BSTabrisCameraResolution*, NSArray<NSNumber *>*> BSTabrisFrameDurationsForResolutions;

@interface ESBarcodeScanner () <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) ESScannerView *scanner;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) NSString *lastData;
@property (strong, nonatomic) NSString *lastFormat;
@property (assign, nonatomic) NSTimeInterval lastSent;
@property (strong, nonatomic) CodeDispatcher *backgroundCodeDispatcher;

@property (nonatomic, strong, readonly) BSTabrisCameraResolution *resolution;
@property (nonatomic, strong, readonly) NSArray<BSTabrisCameraResolution *> *availableResolutions;
@property (nonatomic, strong, readonly) NSNumber *frameDuration;
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *availableFrameDurations;
@property (nonatomic, strong, readonly) BSTabrisFrameDurationsForResolutions *frameDurationsForResolutions;

@end

@implementation ESBarcodeScanner {
    BSTabrisCameraResolution *_resolution;
    NSNumber *_frameDuration;
}

- (instancetype)initWithObjectId:(NSString *)objectId properties:(NSDictionary *)properties inContext:(id<TabrisContext>)context {
    self = [super initWithObjectId:objectId properties:properties inContext:context];
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create("ESBarcodeScanner_queue", DISPATCH_QUEUE_SERIAL);
        self.backgroundCodeDispatcher = [[CodeDispatcher alloc] initWithQueue:queue synchronous:NO];
        self.scanner = [ESScannerView new];
        [self registerSelector:@selector(start:) forCall:@"start"];
        [self registerSelector:@selector(stop) forCall:@"stop"];
        [self defineWidgetView:self.scanner];
        self.camera = properties[@"camera"] ?: @"back";
        self.scaleMode = properties[@"scaleMode"] ?: @"fit";

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(captureSessionRuntimeErrorNotification:)
                                                     name:AVCaptureSessionRuntimeErrorNotification
                                                   object:nil];
    }
    return self;
}

- (void)destroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSString *)remoteObjectType {
    return @"com.eclipsesource.barcodescanner.BarcodeScannerView";
}

+ (NSMutableSet *)remoteObjectProperties {
    NSMutableSet *set = [super remoteObjectProperties];
    [set addObjectsFromArray:@[@"camera", @"scaleMode", @"resolution", @"availableResolutions", @"frameDuration", @"availableFrameDurations", @"frameDurationsForResolutions"]];
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
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            [self setupAndStartSessionWithProperties:properties];
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            [self sendError:(status == AVAuthorizationStatusDenied) ? @"Camera permission not granted" : @"Camera access restricted"];
            break;
        case AVAuthorizationStatusNotDetermined:
            [self requestCameraAccessThenStartSessionWithProperties:properties];
            break;
    }
}

- (void)stop {
    [self.backgroundCodeDispatcher dispatch:^{ [self.session stopRunning]; }];
}

- (void)initializeSession {
    self.session = [[AVCaptureSession alloc] init];
    self.device = [self getCaptureDevice];
    NSError *error;
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
    self.output.metadataObjectTypes = (formats.count == 0) ? self.output.availableMetadataObjectTypes : [self allowedFormatsFrom:formats];
}

- (NSArray<NSNumber *> *)allowedFormatsFrom:(NSArray *)formats {
    NSMutableArray *allowedFormats = [NSMutableArray arrayWithCapacity:formats.count];
    NSDictionary *formatMap = @{
        @"upcA"            : AVMetadataObjectTypeEAN13Code,
        @"upcE"            : AVMetadataObjectTypeUPCECode,
        @"code39"          : AVMetadataObjectTypeCode39Code,
        @"code39Mod43"     : AVMetadataObjectTypeCode39Mod43Code,
        @"code93"          : AVMetadataObjectTypeCode93Code,
        @"code128"         : AVMetadataObjectTypeCode128Code,
        @"ean8"            : AVMetadataObjectTypeEAN8Code,
        @"ean13"           : AVMetadataObjectTypeEAN13Code,
        @"pdf417"          : AVMetadataObjectTypePDF417Code,
        @"qr"              : AVMetadataObjectTypeQRCode,
        @"aztec"           : AVMetadataObjectTypeAztecCode,
        @"interleaved2of5" : AVMetadataObjectTypeInterleaved2of5Code,
        @"itf"             : AVMetadataObjectTypeITF14Code,
        @"dataMatrix"      : AVMetadataObjectTypeDataMatrixCode
    };
    for (NSString *format in formats) {
        if (formatMap[format]) [allowedFormats addObject:formatMap[format]];
    }
    return [allowedFormats copy];
}

- (AVCaptureDevice *)getCaptureDevice {
    return ([self.camera isEqualToString:@"front"]) ? [self frontCamera] : [self rearCamera];
}

- (AVCaptureDevice *)frontCamera {
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == AVCaptureDevicePositionFront) {
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
        [self fireEventNamed:@"detect" withAttributes:@{@"format": format, @"data": data}];
    }
}

- (void)sendError:(NSString *)error {
    if (self.errorListener) {
        [self fireEventNamed:@"error" withAttributes:@{@"error": error ?: [NSNull null]}];
    }
}

- (void)setResolution:(BSTabrisCameraResolution *)resolution {
    AVCaptureDeviceFormat *format = [self captureFormatWithResolution:resolution];
    if (!format) {
        [NSException raise:ESBarcodeScannerExceptionName format:@"`AVCaptureDeviceFormat` with requested resolution (%@) not found.", resolution];
    }
    [self updateCaptureFormat:format];
    _resolution = format.tabrisResolution;
}

- (BSTabrisCameraResolution *)resolution {
    return _resolution ?: (_resolution = [self getCaptureDevice].activeFormat.tabrisResolution);
}
- (void)setFrameDuration:(NSNumber *)frameDuration {
    AVCaptureDeviceFormat *format = [self captureFormatWithResolution:self.resolution frameDuration:frameDuration.doubleValue];
    if (!format) {
        [NSException raise:ESBarcodeScannerExceptionName format:@"`AVCaptureDeviceFormat` with requested resolution (%@) and frame rate (%f) not found.", self.resolution, frameDuration.doubleValue];
    }
    [self updateCaptureFormat:format frameDuration:frameDuration.doubleValue];
    _frameDuration = frameDuration;
}

- (NSNumber *)frameDuration {
    if (!_frameDuration) {
        CMTime frameDuration = [self getCaptureDevice].activeVideoMinFrameDuration;
        _frameDuration = @(frameDuration.timescale / frameDuration.value);
    }
    return _frameDuration;
}

- (NSArray<BSTabrisCameraResolution *> *)availableResolutions {
    AVCaptureDevice *device = self.device ?: [self getCaptureDevice];
    NSMutableSet *resolutionsSet = [NSMutableSet set];
    for (AVCaptureDeviceFormat *format in device.formats) {
        [resolutionsSet addObject:[BSCameraResolution withCaptureDeviceFormat:format]];
    }
    NSArray *sorted = [resolutionsSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    return [self cameraResolutionsToTabrisArray:sorted];
}

- (NSArray<NSNumber *> *)availableFrameDurations {
    return [self availableFrameDurationsForResolution:self.resolution];
}

- (void)captureSessionRuntimeErrorNotification:(NSNotification *)notification {
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    [self.context.asyncCodeDispatcher dispatch:^{ [self sendError:error.localizedDescription ?: error.description]; }];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            NSString *data = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            NSString *format = metadata.type;
            if (data && format && (![format isEqualToString:self.lastFormat] || ![data isEqualToString:self.lastData] || [[NSDate date] timeIntervalSince1970] - self.lastSent > 1)) {
                [self sendDetect:data format:format];
                self.lastData = data;
                self.lastFormat = format;
                self.lastSent = [[NSDate date] timeIntervalSince1970];
            }
        }
    }
}

#pragma mark - Private methods

- (void)setupAndStartSessionWithProperties:(NSDictionary *)properties {
    if (!self.session) [self initializeSession];
    if (self.session) {
        [self setFormats:properties[@"formats"]];
        [self.scanner addSession:self.session];
        [self.backgroundCodeDispatcher dispatch:^{
            [self.session startRunning];
            AVCaptureDeviceFormat *format = [self captureFormatWithResolution:self.resolution frameDuration:self.frameDuration.doubleValue];
            [self updateCaptureFormat:format frameDuration:self.frameDuration.doubleValue];
        }];
    }
}

- (void)requestCameraAccessThenStartSessionWithProperties:(NSDictionary *)properties {
    __weak __typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{ [strongSelf start:properties]; });
        } else {
            [strongSelf sendError:@"Camera permission not granted"];
        }
    }];
}

- (BSTabrisFrameDurationsForResolutions *)frameDurationsForResolutions {
    BSTabrisFrameDurationsForResolutions *frameDurationsForResolutions = [NSMutableDictionary new];
    AVCaptureDevice *device = [self getCaptureDevice];
    for (AVCaptureDeviceFormat *format in device.formats) {
        BSTabrisCameraResolution *cameraResolution = [BSCameraResolution withCaptureDeviceFormat:format].toTabrisDictionary;
        if (!frameDurationsForResolutions[cameraResolution]) {
            frameDurationsForResolutions[cameraResolution] = [self availableFrameDurationsForResolution:cameraResolution];
        }
    }
    NSMutableArray *cameraResolutionsWithFrameDurations = [NSMutableArray array];
    [frameDurationsForResolutions enumerateKeysAndObjectsUsingBlock:^(BSTabrisCameraResolution *key, NSArray<NSNumber *> *obj, BOOL *stop) {
        NSMutableDictionary *merged = key.mutableCopy;
        merged[@"frameDurations"] = obj;
        [cameraResolutionsWithFrameDurations addObject:merged.copy];
    }];
    return cameraResolutionsWithFrameDurations.copy;
}

- (NSArray<NSNumber *> *)availableFrameDurationsForResolution:(BSTabrisCameraResolution *)resolution {
    NSMutableArray<NSNumber *> *frameDurations = [NSMutableArray array];
    AVCaptureDevice *device = self.device ?: [self getCaptureDevice];
    for (AVCaptureDeviceFormat *format in device.formats) {
        if ([format.tabrisResolution isEqualToDictionary:resolution]) {
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                NSNumber *frameDuration = @(range.maxFrameRate);
                if (![frameDurations containsObject:frameDuration]) [frameDurations addObject:frameDuration];
            }
        }
    }
    return frameDurations;
}

- (void)updateCaptureFormat:(AVCaptureDeviceFormat *)format {
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        self.device.activeFormat = format;
        _frameDuration = nil;
        [self.device unlockForConfiguration];
    } else if (error) {
        [NSException raise:ESBarcodeScannerExceptionName format:@"Error locking configuration: %@", error.localizedDescription];
    }
}

- (void)updateCaptureFormat:(AVCaptureDeviceFormat *)format frameDuration:(CGFloat)frameDuration {
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        self.device.activeFormat = format;
        self.device.activeVideoMinFrameDuration = CMTimeMake(1, frameDuration);
        self.device.activeVideoMaxFrameDuration = CMTimeMake(1, frameDuration);
        _frameDuration = nil;
        [self.device unlockForConfiguration];
    } else if (error) {
        [NSException raise:ESBarcodeScannerExceptionName format:@"Error locking configuration: %@", error.localizedDescription];
    }
}

- (AVCaptureDeviceFormat *)captureFormatWithResolution:(BSTabrisCameraResolution *)resolution {
    AVCaptureDevice *device = self.device ?: [self getCaptureDevice];
    for (AVCaptureDeviceFormat *format in device.formats) {
        if ([format.tabrisResolution isEqualToDictionary:resolution]) {
            return format;
        }
    }
    return nil;
}

- (AVCaptureDeviceFormat *)captureFormatWithResolution:(BSTabrisCameraResolution *)resolution frameDuration:(CGFloat)frameDuration {
    AVCaptureDevice *device = self.device ?: [self getCaptureDevice];
    for (AVCaptureDeviceFormat *format in device.formats) {
        if ([format.tabrisResolution isEqualToDictionary:resolution]) {
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                if (range.minFrameRate <= frameDuration && range.maxFrameRate >= frameDuration) {
                    return format;
                }
            }
        }
    }
    return nil;
}

- (NSArray<BSTabrisCameraResolution *> *)cameraResolutionsToTabrisArray:(NSArray<BSCameraResolution *> *)cameraResolutions {
    NSMutableArray<BSTabrisCameraResolution *> *tabrisArray = [NSMutableArray arrayWithCapacity:cameraResolutions.count];
    for (BSCameraResolution *resolution in cameraResolutions) {
        BSTabrisCameraResolution *tabrisResolution = resolution.toTabrisDictionary;
        if (![tabrisArray containsObject:tabrisResolution]) [tabrisArray addObject:tabrisResolution];
    }
    return tabrisArray;
}

@end
