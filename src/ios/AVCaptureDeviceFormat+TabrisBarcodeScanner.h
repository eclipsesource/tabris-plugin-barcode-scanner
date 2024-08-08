//
//  AVCaptureDeviceFormat+TabrisBarcodeScanner.h
//  Barcode scanner example for Tabris.js
//
//  Created by Karol Szafranski on 09.08.24.
//

#import <AVFoundation/AVFoundation.h>
#import "BSCameraResolution.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVCaptureDeviceFormat (TabrisBarcodeScanner)

@property (nonatomic, readonly) BSTabrisCameraResolution* tabrisResolution;

@end

NS_ASSUME_NONNULL_END
