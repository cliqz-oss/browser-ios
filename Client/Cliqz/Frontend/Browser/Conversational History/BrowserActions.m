//
//  ReactToNativeNavigator.m
//  Client
//
//  Created by Sahakyan on 5/18/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(BrowserActions, NSObject)

RCT_EXTERN_METHOD(queryCliqz:(NSString)url)

RCT_EXTERN_METHOD(openLink:(NSString)url)

RCT_EXTERN_METHOD(getOpenTabs:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(openTab:(NSInteger)tabID)

RCT_EXTERN_METHOD(getReminders:(NSString)domain resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end
