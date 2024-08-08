//
//  BSCameraResolution.h
//  Barcode scanner example for Tabris.js
//
//  Created by Karol Szafranski on 07.08.24.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define BSCameraResolutionWidthKey @"width"
#define BSCameraResolutionHeightKey @"height"

typedef NSDictionary<NSString*,NSNumber*> BSTabrisCameraResolution;

NS_ASSUME_NONNULL_BEGIN

@interface BSCameraResolution : NSObject<NSCopying>

@property (assign, nonatomic, readonly) NSUInteger width;
@property (assign, nonatomic, readonly) NSUInteger height;
@property (assign, nonatomic, readonly) NSUInteger numberOfPixels;

+ (instancetype)withWidth:(NSUInteger)width andHeight:(NSUInteger)height;
+ (instancetype)withCaptureDeviceFormat:(AVCaptureDeviceFormat*)captureDeviceFormat;
+ (instancetype)withDictionary:(BSTabrisCameraResolution*)dictionary;

- (BSTabrisCameraResolution *)toTabrisDictionary;
- (NSComparisonResult)compare:(BSCameraResolution *)otherCameraResolution;

@end

NS_ASSUME_NONNULL_END
