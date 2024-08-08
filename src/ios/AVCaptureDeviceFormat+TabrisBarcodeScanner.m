//
//  AVCaptureDeviceFormat+TabrisBarcodeScanner.m
//  Barcode scanner example for Tabris.js
//
//  Created by Karol Szafranski on 09.08.24.
//

#import "AVCaptureDeviceFormat+TabrisBarcodeScanner.h"

@implementation AVCaptureDeviceFormat (TabrisBarcodeScanner)

- (BSTabrisCameraResolution*)tabrisResolution {
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(self.formatDescription);
    return @{
        BSCameraResolutionWidthKey: @(dimensions.width),
        BSCameraResolutionHeightKey: @(dimensions.height)
    };
}

@end
