//
//  URLParser.h
//  Client
//
//  Created by Sahakyan on 6/28/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLDetails: NSObject

	@property(nonatomic, strong) NSString *name;
	@property(nonatomic, strong) NSString *host;

@end

@interface URLParser : NSObject

+ (URLDetails *)getURLDetails:(NSString *)url;

+ (NSString*)getTLD:(NSString *)url;
+ (NSString*)getName:(NSString *)url;

@end
