//
//  URLParser.m
//  Client
//
//  Created by Sahakyan on 6/28/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import "URLParser.h"
#import "URLUtils.hpp"

@implementation URLDetails
@end

@implementation URLParser

- (instancetype)init {
	if (self = [super init]) {
	}
	return self;
}

+ (URLDetails *)getURLDetails:(NSString *)url {
	URLDetails *details = [[URLDetails alloc] init];
	cliqz::UrlDetails d = cliqz::getDetailsFromUrl([url cStringUsingEncoding:NSUTF8StringEncoding]);
	details.name = [NSString stringWithCString:d.name.c_str() encoding:NSUTF8StringEncoding];
	details.host = [NSString stringWithCString:d.host.c_str() encoding:NSUTF8StringEncoding];
	return details;
}

+ (NSString*)getTLD:(NSString *)url {
	cliqz::UrlDetails d = cliqz::getDetailsFromUrl([url cStringUsingEncoding:NSUTF8StringEncoding]);
	return [NSString stringWithCString:d.tld.c_str() encoding:NSUTF8StringEncoding];
}

+ (NSString*)getName:(NSString *)url {
	cliqz::UrlDetails d = cliqz::getDetailsFromUrl([url cStringUsingEncoding:NSUTF8StringEncoding]);
	return [NSString stringWithCString:d.name.c_str() encoding:NSUTF8StringEncoding];
}

@end
