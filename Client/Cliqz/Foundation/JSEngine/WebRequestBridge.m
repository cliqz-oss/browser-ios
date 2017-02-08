//
//  WebRequestBridge.m
//  jsengine
//
//  Created by Sam Macbeth on 19/01/2017.
//  Copyright © 2017 Cliqz GmbH. All rights reserved.
//

#import "RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(WebRequest, NSObject)

RCT_EXTERN_METHOD(isWindowActive:(nonnull NSNumber *)tabId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end
