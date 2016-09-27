//
//  LegacyJSContext.m
//  Client
//
//  Created by Mahmoud Adam on 8/10/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//


#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>
//#import "Client-Swift.h"

@interface FrameInfoWrapper : WKFrameInfo
@property (atomic, retain) NSURLRequest* writableRequest;
@end

@implementation FrameInfoWrapper

-(NSURLRequest*)request
{
    return self.writableRequest;
}

-(BOOL)isMainFrame
{
    return true;
}

@end

@interface LegacyScriptMessage: WKScriptMessage
@property (atomic, retain) NSObject* writeableBody;
@property (atomic, copy) NSString* writableName;
@property (atomic, retain) NSURLRequest* request;
@end
@implementation LegacyScriptMessage

-(id)body
{
    return self.writeableBody;
}

- (NSString*)name
{
    return self.writableName;
}

-(WKFrameInfo *)frameInfo
{
    static FrameInfoWrapper* f = 0;
    if (!f)
        f = [FrameInfoWrapper new];
    f.writableRequest = self.request;
    return f;
}

@end

@implementation LegacyJSContext

typedef void(^JSCallbackBlock)(NSDictionary*);

LegacyScriptMessage *message_ = 0;
WKUserContentController *userContentController_ = 0;

// Used to lookup the callback needed for a given handler name
NSMutableDictionary<NSString *, JSCallbackBlock> *callbackBlocks_ = 0;
NSMapTable<NSNumber *, UIWebView *> *handlerToWebview_ = 0;

// Handy method for getting unique values from object address to use as keys in a dict/hash
NSNumber* objToKey(id object) {
    return [NSNumber numberWithLongLong:(uintptr_t)object];
}

JSCallbackBlock blockFactory(NSString *handlerName, id<WKScriptMessageHandler> handler, UIWebView *webView)
{
    if (!handlerToWebview_) {
        handlerToWebview_ = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    [handlerToWebview_ setObject:webView forKey:objToKey(handler)];
    
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@", handlerName, objToKey(handler), objToKey(webView)];
    
    if (!callbackBlocks_) {
        callbackBlocks_ = [NSMutableDictionary dictionary];
    }
    
    JSCallbackBlock result = [callbackBlocks_ objectForKey:key];
    if (result) {
        return result;
    }
    
    result =  ^(NSDictionary* message) {
        dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
            //NSLog(@"%@ %@", handlerName, message);
#endif
            if (!message_) {
                message_ = [LegacyScriptMessage new];
                userContentController_ = [WKUserContentController new];
            }
            
            message_.writeableBody = message;
            message_.writableName = handlerName;
            if (handlerToWebview_) {
                UIWebView *webView = [handlerToWebview_ objectForKey:objToKey(handler)];
                if (webView) {
                    message_.request = webView.request;
                }
            }
            
            [handler userContentController:userContentController_ didReceiveScriptMessage:message_];
        });
    };
    
    [callbackBlocks_ setObject:result forKey:key];
    
    return result;
}

- (void)installHandlerForContext:(id)_context
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
                         webView:(UIWebView *)webView
{
    
    JSContext* context = _context;
    NSString* script = [NSString stringWithFormat:@""
                        "if (!window.hasOwnProperty('webkit')) {"
                        "  Window.prototype.webkit = {};"
                        "  Window.prototype.webkit.messageHandlers = {};"
                        "}"
                        "if (!window.webkit.messageHandlers.hasOwnProperty('%@'))"
                        "  Window.prototype.webkit.messageHandlers.%@ = {};",
                        handlerName, handlerName];
    
    [context evaluateScript:script];
    
    context[@"Window"][@"prototype"][@"webkit"][@"messageHandlers"][handlerName][@"postMessage"] =
    blockFactory(handlerName, handler, webView);
}

- (void)installHandlerForWebView:(UIWebView *)webView
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
{
    assert([NSThread isMainThread]);
    JSContext* context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    [self installHandlerForContext:context handlerName:handlerName handler:handler webView:webView];
}

- (void)windowOpenOverride:(UIWebView *)webView context:(id)_context
{
    assert([NSThread isMainThread]);
    JSContext *context = _context;
    if (!context) {
        context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    }
    
    if (!context) {
        return;
    }
    
//    context[@"window"][@"open"] = ^(NSString *url) {
//        [HandleJsWindowOpen open:url];
//    };
}


- (void)callOnContext:(id)context script:(NSString*)script
{
    JSContext* ctx = context;
    [ctx evaluateScript:script];
}

- (NSArray *)findNewFramesForWebView:(UIWebView *)webView withFrameContexts:(NSSet*)contexts
{
    NSArray *frames = [webView valueForKeyPath:@"documentView.webView.mainFrame.childFrames"];
    NSMutableArray *result = [NSMutableArray array];
    
    [frames enumerateObjectsUsingBlock:^(id frame, NSUInteger idx, BOOL *stop ) {
        JSContext *context = [frame valueForKeyPath:@"javaScriptContext"];
        if (context && ![contexts containsObject:[NSNumber numberWithUnsignedInteger:context.hash]]) {
            [result addObject:context];
        }
    }];
    return result;
}

@end
