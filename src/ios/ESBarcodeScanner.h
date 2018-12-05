//
//  ESBarcodeScanner.h
//  tabris-plugin-barcode-scanner
//
//  Created by Patryk Mól on 06.02.2018.
//  Copyright (c) 2018 EclipseSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Tabris/Widget.h>

@interface ESBarcodeScanner : Widget
@property (strong, nonatomic) NSString *camera;
@property (assign, nonatomic) BOOL detectListener;
@property (assign, nonatomic) BOOL errorListener;
@property (strong, nonatomic) NSString *scaleMode;
- (void)start:(NSDictionary *)properties;
- (void)stop;
@end
