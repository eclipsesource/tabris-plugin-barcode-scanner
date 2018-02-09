//
//  ESScannerView.h
//  tabris-plugin-barcode-scanner
//
//  Created by Patryk Mól on 06.02.2018.
//  Copyright (c) 2018 EclipseSource. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ESScannerView : UIView
@property (strong, nonatomic) NSString *scaleMode;
- (void)addSession:(AVCaptureSession *)session;
@end
