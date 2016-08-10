//
//  LegacyJSContext.h
//  Client
//
//  Created by Mahmoud Adam on 8/10/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

#ifndef LegacyJSContext_h
#define LegacyJSContext_h

@import WebKit;
@import UIKit;

@interface LegacyJSContext : NSObject

-(void)installHandlerForWebView:(UIWebView *)wv
                    handlerName:(NSString *)handlerName
                        handler:(id<WKScriptMessageHandler>)handler;

- (void)installHandlerForContext:(id)context
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
                         webView:(UIWebView *)webView;

- (void)callOnContext:(id)context script:(NSString*)script;

-(NSArray*)findNewFramesForWebView:(UIWebView *)webView withFrameContexts:(NSSet *)contexts;

- (void)windowOpenOverride:(UIWebView *)webView context:(id)context;
@end


#endif /* LegacyJSContext_h */
