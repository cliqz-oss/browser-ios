//
//  WebViewScripting.swift
//  Client
//
//  Created by Mahmoud Adam on 8/10/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

class LegacyUserContentController
{
    var scriptHandlersMainFrame = [String:WKScriptMessageHandler]()
    var scriptHandlersSubFrames = [String:WKScriptMessageHandler]()
    
    var scripts:[WKUserScript] = []
    weak var webView: CliqzWebView?
    
    func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptHandlersMainFrame[name] = scriptMessageHandler
    }
    
    func removeScriptMessageHandler(name name: String) {
        scriptHandlersMainFrame.removeValueForKey(name)
        scriptHandlersSubFrames.removeValueForKey(name)
    }
    
    func addUserScript(script:WKUserScript) {
        var mainFrameOnly = true
        if !script.forMainFrameOnly {
            debugPrint("Inject to subframes")
            // Only contextMenu injection to subframes for now,
            // whitelist this explicitly, don't just inject scripts willy-nilly into frames without
            // careful consideration. For instance, there are security implications with password management in frames
            mainFrameOnly = false
        }
        scripts.append(WKUserScript(source: script.source, injectionTime: script.injectionTime, forMainFrameOnly: mainFrameOnly))
    }
    
    init(_ webView: CliqzWebView) {
        self.webView = webView
    }
    
    func injectIntoMain() {
        guard let webView = webView else { return }
        
        let result = webView.stringByEvaluatingJavaScriptFromString("window.hasOwnProperty('__firefox__')")
        if result == "true" {
            // already injected into this context
            return
        }

	let js = LegacyJSContext()
        js.windowOpenOverride(webView, context:nil)

        for (name, handler) in scriptHandlersMainFrame {
            js.installHandlerForWebView(webView, handlerName: name, handler:handler)
        }

        for script in scripts {
            webView.stringByEvaluatingJavaScriptFromString(script.source)
        }
    }
    
    func injectIntoSubFrame() {
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: webView?.knownFrameContexts)
        
        for ctx in contexts {
            js.windowOpenOverride(webView, context:ctx)
            
            webView?.knownFrameContexts.insert(ctx.hash)
            
            for (name, handler) in scriptHandlersSubFrames {
                js.installHandlerForContext(ctx, handlerName: name, handler:handler, webView:webView)
            }
            for script in scripts {
                if !script.forMainFrameOnly {
                    js.callOnContext(ctx, script: script.source)
                }
            }
        }
    }
    
    static func injectJsIntoAllFrames(webView: CliqzWebView, script: String) {
        webView.stringByEvaluatingJavaScriptFromString(script)
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: nil)
        for ctx in contexts {
            js.callOnContext(ctx, script: script)
        }
    }

    func injectJsIntoPage() {
        injectIntoMain()
        injectIntoSubFrame()
    }

}

class CliqzWebViewConfiguration
{
    let userContentController: LegacyUserContentController
    init(webView: CliqzWebView) {
        userContentController = LegacyUserContentController(webView)
    }
}
