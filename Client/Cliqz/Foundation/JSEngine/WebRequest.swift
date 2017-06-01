//
//  WebRequest.swift
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(WebRequest)
open class WebRequest : RCTEventEmitter {
    
    var tabs = NSMapTable<AnyObject, AnyObject>.strongToWeakObjects()
    var requestSerial = 0
    var blockingResponses = [Int: NSDictionary]()
    var lockSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    var ready = false
    
    public override init() {
        super.init()
        URLProtocol.registerClass(InterceptorURLProtocol)
    }
    
    open override static func moduleName() -> String! {
        return "WebRequest"
    }
    
    override open func supportedEvents() -> [String]! {
        return ["webRequest"]
    }
    
    func shouldBlockRequest(_ request: URLRequest) -> Bool {

        let requestInfo = getRequestInfo(request)
        
        // reset counter for main document
        if request.url == request.mainDocumentURL {
            if let tabId = requestInfo["tabId"] as? Int, let webView = WebViewToUAMapper.idToWebView(tabId) {
                webView.updateUnsafeRequestsCount(0)
            }
        }
        
        let response = Engine.sharedInstance.getBridge().callAction("webRequest", args: [requestInfo])
        if let blockResponse = response["result"] as? NSDictionary, blockResponse["cancel"] != nil {
            print("xxxxx -> block \(String(describing: request.url))")
            // update unsafe requests count for the webivew that issued this request
            if let tabId = requestInfo["tabId"] as? Int, let webView = WebViewToUAMapper.idToWebView(tabId),
                let _ = blockResponse["source"] {
                let unsafeRequestsCount = webView.unsafeRequests
                webView.updateUnsafeRequestsCount(unsafeRequestsCount + 1)
            }
            return true
        }
        
        return false
    }
    
    func newTabCreated(_ tabId: Int, webView: UIView) {
        tabs.setObject(webView, forKey: NSNumber(value: tabId as Int))
    }
    
    @objc(isWindowActive:resolve:reject:)
    func isWindowActive(_ tabId: NSNumber, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let active = isTabActive(tabId.intValue)
        resolve(active)
    }
    
    
    //MARK: - Private Methods
    fileprivate func isTabActive(_ tabId: Int) -> Bool {
        return tabs.object(forKey: tabId as AnyObject?) != nil
    }
    
    fileprivate func getRequestInfo(_ request: URLRequest) -> [String: Any] {
        let requestId = requestSerial;
        requestSerial += 1
        let url = request.url?.absoluteString
        let userAgent = request.allHTTPHeaderFields?["User-Agent"]
        
        let isMainDocument = request.url == request.mainDocumentURL
        let tabId = getTabId(userAgent)
        let isPrivate = false
        let originUrl = request.mainDocumentURL?.absoluteString
        
        var requestInfo = [String: Any]()
        requestInfo["id"] = requestId
        requestInfo["url"] = url
        requestInfo["method"] = request.httpMethod as AnyObject?
        requestInfo["tabId"] = tabId ?? -1
        requestInfo["parentFrameId"] = -1
        // TODO: frameId how to calculate
        requestInfo["frameId"] = tabId ?? -1
        requestInfo["isPrivate"] = isPrivate
        requestInfo["originUrl"] = originUrl
        let contentPolicyType = ContentPolicyDetector.sharedInstance.getContentPolicy(request, isMainDocument: isMainDocument)
        requestInfo["type"] = contentPolicyType
        requestInfo["source"] = originUrl
        
        requestInfo["requestHeaders"] = request.allHTTPHeaderFields
        return requestInfo
    }
    
    open class func generateUniqueUserAgent(_ baseUserAgent: String, tabId: Int) -> String {
        let uniqueUserAgent = baseUserAgent + String(format:" _id/%06d", tabId)
        return uniqueUserAgent
    }
    
    fileprivate func getTabId(_ userAgent: String?) -> Int? {
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.range(of: "_id/") else {
            // the first created webview doesn't have the id, because at this point there is no way to get the user agent automatically
            return 1
        }
		
		let tabIdString = userAgent.substring(with: loc.upperBound..<userAgent.index(loc.upperBound, offsetBy: 6))
        guard let tabId = Int(tabIdString) else { return nil }
        return tabId
    }
    
    fileprivate func toJSONString(_ anyObject: AnyObject) -> String? {
        do {
            if JSONSerialization.isValidJSONObject(anyObject) {
                let jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: JSONSerialization.WritingOptions(rawValue: 0))
                let jsonString = String(data:jsonData, encoding: String.Encoding.utf8)!
                return jsonString
            } else {
                debugPrint("[toJSONString] the following object is not valid JSON: \(anyObject)")
            }
        } catch let error as NSError {
            debugPrint("[toJSONString] JSON conversion of: \(anyObject) \n failed with error: \(error)")
        }
        return nil
    }
    
}
