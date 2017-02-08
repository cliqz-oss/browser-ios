//
//  JSBridgeBridge.m
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import "RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(JSBridge, NSObject)

RCT_EXTERN_METHOD(replyToAction:(nonnull NSInteger *)actionId response:(NSDictionary)response error:(NSString)error)
RCT_EXTERN_METHOD(registerAction:)

@end
