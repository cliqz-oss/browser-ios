//
//  HistoryBridge.m
//  Client
//
//  Created by Sam Macbeth on 27/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(HistoryBridge, NSObject)

RCT_EXTERN_METHOD(syncHistory:(nonnull NSInteger *)fromIndex resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(pushHistory:(NSDictionary)historyItems)

@end
