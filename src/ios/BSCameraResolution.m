//
//  BSCameraResolution.m
//  Barcode scanner example for Tabris.js
//
//  Created by Karol Szafranski on 07.08.24.
//

#import "BSCameraResolution.h"
#import <Tabris/Tabris.h>

@interface BSCameraResolution()

@property (assign, nonatomic, readwrite) NSUInteger width;
@property (assign, nonatomic, readwrite) NSUInteger height;
@property (assign, nonatomic, readwrite) NSUInteger numberOfPixels;

@end

@implementation BSCameraResolution

+ (instancetype)withWidth:(NSUInteger)width andHeight:(NSUInteger)height {
    BSCameraResolution* cameraResolution = [BSCameraResolution new];
    cameraResolution.width = width;
    cameraResolution.height = height;
    return cameraResolution;
}

+ (instancetype)withVideoDimensions:(CMVideoDimensions)videoDimensions {
    return [BSCameraResolution withWidth:videoDimensions.width
                             andHeight:videoDimensions.height];
}

+ (instancetype)withDictionary:(NSDictionary*)dictionary {
    NSNumber* width = [dictionary objectForKey:BSCameraResolutionWidthKey];
    width = [width objectAsInstanceOf:[NSNumber class]];

    NSNumber* height = [dictionary objectForKey:BSCameraResolutionHeightKey];
    height = [height objectAsInstanceOf:[NSNumber class]];

    if (width && height) {
        return [BSCameraResolution withWidth:width.unsignedIntegerValue
                                 andHeight:height.unsignedIntegerValue];
    }
    return nil;
}

+ (instancetype)withCaptureDeviceFormat:(AVCaptureDeviceFormat*)captureDeviceFormat {
    BSCameraResolution* cameraResolution;
    CMFormatDescriptionRef formatDescription = captureDeviceFormat.formatDescription;
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDescription);
    if (mediaType == kCMMediaType_Video) {
        CMVideoFormatDescriptionRef videoFormatDescription = formatDescription;
        CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription);
        cameraResolution = [BSCameraResolution withVideoDimensions:videoDimensions];
    }
    return cameraResolution;
}

- (NSComparisonResult)compare:(BSCameraResolution *)otherBSCameraResolution {
    if (self.numberOfPixels > otherBSCameraResolution.numberOfPixels) {
        return NSOrderedDescending;
    }
    else if(self.numberOfPixels < otherBSCameraResolution.numberOfPixels) {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

- (NSUInteger)numberOfPixels {
    if(_numberOfPixels == 0) {
        _numberOfPixels = self.width * self.height;
    }
    return _numberOfPixels;
}

- (NSUInteger)hash {
    return @(self.numberOfPixels).hash;
}

- (BOOL)isEqual:(id)object {
    BSCameraResolution* otherBSCameraResolution = [NSObject object:object asInstanceOf:[BSCameraResolution class]];
    BOOL isEqual = self.hash == otherBSCameraResolution.hash;
    return isEqual;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p width=%lui height=%lui numberOfPixels=%lui>", NSStringFromClass(self.class), self, (unsigned long)self.width, (unsigned long)self.height, (unsigned long)self.numberOfPixels];
}

- (BSTabrisCameraResolution *)toTabrisDictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @(self.width), BSCameraResolutionWidthKey,
            @(self.height), BSCameraResolutionHeightKey,
            nil];
}

-(id)copyWithZone:(NSZone *)zone {
    BSCameraResolution* cameraResolution = [[BSCameraResolution allocWithZone:zone] init];
    cameraResolution.width = self.width;
    cameraResolution.height = self.height;
    return cameraResolution;
}

@end
