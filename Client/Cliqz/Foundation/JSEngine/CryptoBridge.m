//
//  CryptoBridge.m
//  Client
//
//  Created by Mahmoud Adam on 7/17/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Crypto, NSObject)

RCT_EXTERN_METHOD(generateRandomSeed:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(generateRSAKey:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end
