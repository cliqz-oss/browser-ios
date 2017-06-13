//
//  HistoryModuleBridge.m
//  Client
//
//  Created by Tim Palade on 5/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(HistoryModule, NSObject)

RCT_EXTERN_METHOD(query:(nonnull NSNumber *)limit startFrame:(nonnull NSNumber *)startFrame endFrame:(nonnull NSNumber *)endFrame domain:(NSString*)domain resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end
