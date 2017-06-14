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
    
    func addScriptMessageHandler(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptHandlersMainFrame[name] = scriptMessageHandler
    }
    
    func removeScriptMessageHandler(_ name: String) {
        scriptHandlersMainFrame.removeValue(forKey: name)
        scriptHandlersSubFrames.removeValue(forKey: name)
    }
    
    func addUserScript(_ script:WKUserScript) {
        var mainFrameOnly = true
        if !script.isForMainFrameOnly {
            print("Inject to subframes")
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
        
        let result = webView.stringByEvaluatingJavaScript(from: "window.hasOwnProperty('__firefox__')")
        if result == "true" {
            // already injected into this context
            return
        }

	let js = LegacyJSContext()
        js.windowOpenOverride(webView, context:nil)

        for (name, handler) in scriptHandlersMainFrame {
            js.installHandler(for: webView, handlerName: name, handler:handler)
        }

        for script in scripts {
            webView.stringByEvaluatingJavaScript(from: script.source)
        }
    }
    
    func injectIntoSubFrame() {
        let js = LegacyJSContext()
        let contexts = js.findNewFrames(for: webView, withFrameContexts: webView?.knownFrameContexts)
        
        for ctx in contexts! {
            js.windowOpenOverride(webView, context:ctx)
            
            webView?.knownFrameContexts.insert((ctx as AnyObject).hash as NSObject)
            
            for (name, handler) in scriptHandlersSubFrames {
                js.installHandler(forContext: ctx, handlerName: name, handler:handler, webView:webView)
            }
            for script in scripts {
                if !script.isForMainFrameOnly {
                    js.call(onContext: ctx, script: script.source)
                }
            }
        }
    }
    
    static func injectJsIntoAllFrames(_ webView: CliqzWebView, script: String) {
        webView.stringByEvaluatingJavaScript(from: script)
        let js = LegacyJSContext()
        let contexts = js.findNewFrames(for: webView, withFrameContexts: nil)
        for ctx in contexts! {
            js.call(onContext: ctx, script: script)
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
