//
//  ESScannerView.h
//  tabris-plugin-barcode-scanner
//
//  Created by Patryk Mól on 06.02.2018.
//  Copyright (c) 2018 EclipseSource. All rights reserved.
//

#import "ESScannerView.h"

@interface ESScannerView ()
@property (strong) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation ESScannerView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)setScaleMode:(NSString *)scaleMode {
    _scaleMode = scaleMode;
    if ([scaleMode isEqualToString:@"fill"]) {
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    } else {
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
}

- (void)addSession:(AVCaptureSession *)session {
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    self.previewLayer.frame = self.bounds;
    self.scaleMode = self.scaleMode;
    [self.layer addSublayer:self.previewLayer];
    [self rotatePreviewLayer];
    [self resizePreviewLayer];
}

- (void)updatePreviewLayerForOrientation {
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [self rotatePreviewLayer];
    [self resizePreviewLayer];
    [CATransaction commit];
}

- (void)rotatePreviewLayer {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self.previewLayer setAffineTransform:CGAffineTransformMakeRotation(0)];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [self.previewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI/2)];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [self.previewLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI/2)];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self.previewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI)];
            break;
        default:
            break;
    }
}

- (void)resizePreviewLayer {
    CGSize newSize = self.bounds.size;
    self.previewLayer.frame = self.bounds;
    self.previewLayer.position = CGPointMake(0.5 * newSize.width, 0.5 * newSize.height);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        [self updatePreviewLayerForOrientation];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"bounds"];
}

@end
