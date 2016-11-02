//
//  AntiTrackingModule.swift
//  Client
//
//  Created by Mahmoud Adam on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore
import Crashlytics


class AntiTrackingModule: NSObject {
    
    //MARK: Constants
    private let context = JSContext()
    private let antiTrackingDirectory = "Extension/build/mobile/search/v8"
    private let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as String
    private let fileManager = NSFileManager.defaultManager()
    private let dispatchQueue = dispatch_queue_create("com.cliqz.AntiTracking", DISPATCH_QUEUE_SERIAL)
    
    private let adBlockABTestPrefName = "cliqz-adb-abtest"
    private let adBlockPrefName = "cliqz-adb"
    
    private let telemetryWhiteList = ["attrack.FP", "attrack.tp_events"]
    private let urlsWhiteList = ["https://cdn.cliqz.com/anti-tracking/bloom_filter/",
                                 "https://cdn.cliqz.com/anti-tracking/whitelist/versioncheck.json",
                                 "https://cdn.cliqz.com/adblocking/mobile/allowed-lists.json"]
    
    // MARK: - Local variables
    var privateMode = false
    var timerCounter = 0
    var timers = [Int: NSTimer]()
    
    //MARK: - Singltone
    static let sharedInstance = AntiTrackingModule()
    
    override init() {
        super.init()
    }
    
    //MARK: - Public APIs
    func initModule() {
        // Register interceptor url protocol
        NSURLProtocol.registerClass(InterceptorURLProtocol)
        
        dispatch_async(dispatchQueue) {
            self.configureExceptionHandler()
			self.loadWindowTimers()
            self.loadModule()
        }
    }

    func shouldBlockRequest(request: NSURLRequest) -> Bool {
        guard BlockedRequestsCache.sharedInstance.hasRequest(request) == false else {
            return true
        }
        let requestInfo = getRequestInfo(request)
        if let blockResponse = getBlockResponseForRequest(requestInfo) where blockResponse.count > 0 {
            
            // update unsafe requests count for the webivew that issued this request
            if let tabId = requestInfo["tabId"] as? Int,
                let webView = WebViewToUAMapper.idToWebView(tabId) {
                if let tabBlockInfo = getTabBlockingInfo(tabId),
                    let requests = tabBlockInfo["requests"] as? [String : AnyObject],
                    let unsafeRequestsCount = requests["unsafe"] as? Int {
                        webView.updateUnsafeRequestsCount(unsafeRequestsCount)
                    }
            }
            
            BlockedRequestsCache.sharedInstance.addBlockedRequest(request)
            
            return true
        }
        
        return false
    }

    func setAdblockEnabled(value: Bool) {
        dispatch_async(dispatchQueue) {
            
            if value == true {
                self.extractAdblockerSeedFiles()
            }
            
            self.context.evaluateScript("CliqzUtils.setPref(\"\(self.adBlockPrefName)\", \(value ? 1 : 0));")
            self.context.evaluateScript("CliqzUtils.setPref(\"\(self.adBlockABTestPrefName)\", \(value ? true : false));")
        }
    }

	func getTrackersCount(webViewId: Int) -> Int {
		if let webView = WebViewToUAMapper.idToWebView(webViewId) {
			return webView.unsafeRequests
		}
		return 0
	}

    func getAntiTrackingStatistics(webViewId: Int) -> [(String, Int)] {
        var antiTrackingStatistics = [(String, Int)]()
        if let tabBlockInfo = getTabBlockingInfo(webViewId) {
			if let companies = tabBlockInfo["companies"] as? [String: [String]],
			   let allTrackers = tabBlockInfo["trackers"] as? [String: AnyObject] {

				for (company, trackers) in companies {
					let badRequestsCount = getCompanyBadRequestsCount(trackers, allTrackers:allTrackers)
					if badRequestsCount >= 0 {
						antiTrackingStatistics.append((company, badRequestsCount))
					}
				}
			}
		}
        return antiTrackingStatistics.sort { $0.1 == $1.1 ? $0.0.lowercaseString < $1.0.lowercaseString : $0.1 > $1.1 }
    }
    
    //MARK: - Private Helpers
    private func extractAdblockerSeedFiles() {
        let sourceDirectory = "\(antiTrackingDirectory)/seed-files/adblocking"
        let destinationDirectory = "cliqz/antitracking/adblocking"
        
        if let sourcePath = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent(sourceDirectory)?.path,
            let destinationPath = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent(destinationDirectory)?.path {
            
            if self.fileManager.fileExistsAtPath(destinationPath) == false {
                let allFiles = self.fileManager.enumeratorAtPath(sourcePath)
                
                while let file = allFiles?.nextObject() as? String {
                    if file.endsWith(".txt") {
                        extractFile(file, sourcePath: sourcePath, destinationPath: destinationPath)
                    }
                }
            }
        }
    }
    
    private func extractFile(relativePath: String, sourcePath: String, destinationPath: String) {
        do {
            let absolutePath = sourcePath + "/" + relativePath
            if let content = self.fileManager.contentsAtPath(absolutePath) {
                let unzippedData = try content.gunzippedData()
                
                let fileDesitination = destinationPath + "/" + (relativePath)
                let containingDirectory = NSURL(fileURLWithPath: fileDesitination).URLByDeletingLastPathComponent
                createDirectoryIfNotExist(containingDirectory)
                
                unzippedData.writeToFile(fileDesitination, atomically:true)
            }
        } catch let error as NSError  {
            print("[Error] Could not copy file: \(relativePath), because of the following error: \(error)")
        }
    }
    
    private func getTabBlockingInfo(webViewId: Int) -> [NSObject : AnyObject]! {
        let tabBlockInfo = self.context.evaluateScript("System.get('antitracking/attrack').default.getTabBlockingInfo(\(webViewId));").toDictionary()
        return tabBlockInfo
    }
    
    private func getCompanyBadRequestsCount(trackers: [String], allTrackers: [String: AnyObject]) -> Int {
        var badRequestsCount = 0
        for tracker in trackers {
            if let trackerStatistics = allTrackers[tracker] as? [String: Int] {
                if let badRequests = trackerStatistics["bad_qs"] {
                    badRequestsCount += badRequests
                }
                if let adBlockRequests = trackerStatistics["adblock_block"] {
                    badRequestsCount += adBlockRequests
                }
            }
        }
        return badRequestsCount
    }

    private class func cloneRequest(request: NSURLRequest) -> NSMutableURLRequest {
        // Reportedly not safe to use built-in cloning methods: http://openradar.appspot.com/11596316
        let newRequest = NSMutableURLRequest(URL: request.URL!, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval)
        newRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        if let m = request.HTTPMethod {
            newRequest.HTTPMethod = m
        }
        if let b = request.HTTPBodyStream {
            newRequest.HTTPBodyStream = b
        }
        if let b = request.HTTPBody {
            newRequest.HTTPBody = b
        }
        newRequest.HTTPShouldUsePipelining = request.HTTPShouldUsePipelining
        newRequest.mainDocumentURL = request.mainDocumentURL
        newRequest.networkServiceType = request.networkServiceType
        return newRequest
    }

    private func toJSONString(anyObject: AnyObject) -> String? {
        do {
            if NSJSONSerialization.isValidJSONObject(anyObject) {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(anyObject, options: NSJSONWritingOptions(rawValue: 0))
                let jsonString = String(data:jsonData, encoding: NSUTF8StringEncoding)!
                return jsonString
            } else {
                print("[toJSONString] the following object is not valid JSON: \(anyObject)")
            }
        } catch let error as NSError {
            print("[toJSONString] JSON conversion of: \(anyObject) \n failed with error: \(error)")
        }
        return nil
    }
    
    private func loadModule() {
        
        // register methods
        registerNativeMethods()
        loadJavascriptSource("timers")
        
        if #available(iOS 10, *) {
            loadJavascriptSource("/bower_components/es6-promise/es6-promise")
        } else if #available(iOS 9, *) {
            loadJavascriptSource("/bower_components/es6-promise/es6-promise")
        } else {
			// Quick fix for iOS8: polyfill for ios8
            loadJavascriptSource("/bower_components/es6-promise/es6-promise")
            loadJavascriptSource("/bower_components/core.js/client/core")
        }
		context.evaluateScript("Promise = ES6Promise")
        
        // set up System global for module import
        context.evaluateScript("var exports = {}")
        loadJavascriptSource("system-polyfill")
        context.evaluateScript("var System = exports.System;")
        loadJavascriptSource("fs-polyfill")
        
        // load config file
        loadConfigFile()

        // create legacy CliqzUtils global
         context.evaluateScript("var CliqzUtils = {}; System.import(\"core/utils\").then(function(mod) { CliqzUtils = mod.default; });")

        // pref config
        context.evaluateScript("setTimeout(function () { "
            + "CliqzUtils.setPref(\"antiTrackTest\", true);"
            + "CliqzUtils.setPref(\"attrackForceBlock\", false);"
            + "CliqzUtils.setPref(\"attrackBloomFilter\", true);"
            + "CliqzUtils.setPref(\"attrackDefaultAction\", \"placeholder\");"
            + "}, 100)");
        
        // block ads prefs
        if SettingsPrefs.getAdBlockerPref() {
            context.evaluateScript("setTimeout(function () { "
                + "CliqzUtils.setPref(\"\(adBlockABTestPrefName)\", true);"
                + "CliqzUtils.setPref(\"\(adBlockPrefName)\", 1);"
                + "}, 100)");
        }

        // startup
        context.evaluateScript("setTimeout(function() { "
            + "System.import(\"platform/startup\").then(function(startup) { startup.default() }).catch(function(e) { logDebug(e, 'xxx') });"
            + "}, 200)")
    }

    private func loadJavascriptSource(sourcePath: String) {
        let (sourceName, directory) = getSourceMetaData(sourcePath)
        if let path = NSBundle.mainBundle().pathForResource(sourceName, ofType: "js", inDirectory: directory), script = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            context.evaluateScript(script);
        } else {
            print("Script not found: \(sourcePath)")
        }
    }
    
    private func getSourceMetaData(sourcePath: String) -> (String, String) {
        var sourceName: String
        var directory: String
        if sourcePath.contains("/") {
            var pathComponents = sourcePath.componentsSeparatedByString("/")
            sourceName = pathComponents.last!
            pathComponents.removeLast()
            directory = antiTrackingDirectory + pathComponents.joinWithSeparator("/")
        } else {
            sourceName = sourcePath
            directory = antiTrackingDirectory
        }
        
        if sourceName.endsWith(".js") {
            sourceName = sourceName.replace(".js", replacement: "")
        }
        return (sourceName, directory)
    }
    
    private func loadConfigFile() {
        if let path = NSBundle.mainBundle().pathForResource("cliqz", ofType: "json", inDirectory: "\(antiTrackingDirectory)/config"), let script = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            let formatedScript = script.replace("\"", replacement: "\\\"").replace("\n", replacement: "")
            let configScript = "var __CONFIG__ = JSON.parse(\"\(formatedScript)\");"
            context.evaluateScript(configScript)
        }
    }

    private func configureExceptionHandler() {
        context.exceptionHandler = { context, exception in
            print("JS Error: \(exception)")
        }
    }

    private func registerNativeMethods() {
        registerMd5NativeMethod()
        registerLogDebugMethod()
        registerLoadSubscriptMethod()
        registerMkTempDirMethod()
        registerReadFileMethod()
        registerWriteFileMethod()
        registerHttpHandlerMethod()
        registerSendTelemetryMethod()
        registerIsWindowActiveMethod()
    }

    private func registerMd5NativeMethod() {
        let md5Native: @convention(block) (String) -> String = { data in
            return md5(data)
        }
        context.setObject(unsafeBitCast(md5Native, AnyObject.self), forKeyedSubscript: "_md5Native")
    }

    private func registerLogDebugMethod() {
        let logDebug: @convention(block) (String, String) -> () = { message, key in
//            print("\n\n>>>>>>>> \(key): \(message)\n\n")
        }
        context.setObject(unsafeBitCast(logDebug, AnyObject.self), forKeyedSubscript: "logDebug")
    }

    private func registerLoadSubscriptMethod() {
        let loadSubscript: @convention(block) (String) -> () = {[weak self] subscriptName in
            self?.loadJavascriptSource("/modules\(subscriptName)")
        }
        context.setObject(unsafeBitCast(loadSubscript, AnyObject.self), forKeyedSubscript: "loadSubScript")
        
    }


    @objc private func excuteJavaScriptFunction(timer: NSTimer) -> () {
        dispatch_async(dispatchQueue) {
            if let function = timer.userInfo as? JSValue {
                function.callWithArguments(nil)
            }
        }
    }

    private func registerReadFileMethod() {
        let readFile: @convention(block) (String, JSValue) -> () = { path, callback in
            dispatch_async(self.dispatchQueue) {[weak self] in
				if var p = self?.documentDirectory {
					do {
						p.appendContentsOf("/\(path)")
						let content = try String(contentsOfFile: p, encoding: NSUTF8StringEncoding)
						if content == "undefined" {
							// files does not exist, do no thing
							callback.callWithArguments(nil)
						} else {
							callback.callWithArguments([content])
						}
					} catch let error as NSError {
						// files does not exist, do no thing
						callback.callWithArguments(nil)
					}
				} else {
					callback.callWithArguments(nil)
				}
            }
        }
        context.setObject(unsafeBitCast(readFile, AnyObject.self), forKeyedSubscript: "readFileNative")
		context.setObject(unsafeBitCast(readFile, AnyObject.self), forKeyedSubscript: "readTempFile")
	}

	private func registerWriteFileMethod() {
        let writeFile: @convention(block) (String, String) -> () = {[weak self] path, data in
            if let p = self?.documentDirectory, filePathURL = NSURL(fileURLWithPath: p).URLByAppendingPathComponent(path) {
                do {
                    try data.writeToURL(filePathURL, atomically: true, encoding: NSUTF8StringEncoding)
                } catch let error as NSError {
                    print("WriteFile Failed: ---- \(error)")
                }
            }
        }
        context.setObject(unsafeBitCast(writeFile, AnyObject.self), forKeyedSubscript: "writeFileNative")
        context.setObject(unsafeBitCast(writeFile, AnyObject.self), forKeyedSubscript: "writeTempFile")
    }
    
    private func registerMkTempDirMethod() {
        let mkTempDir: @convention(block) (String) -> () = {[weak self] path in
            self?.createTempDir(path)
        }
        context.setObject(unsafeBitCast(mkTempDir, AnyObject.self), forKeyedSubscript: "mkTempDir")
    }

    private func createTempDir(path: String) {
        if let tempDirectory = NSURL(fileURLWithPath: self.documentDirectory).URLByAppendingPathComponent(path) {
            
            createDirectoryIfNotExist(tempDirectory)
        }
    }
    
    private func createDirectoryIfNotExist(directoryURL: NSURL?){
        if let path = directoryURL?.path where self.fileManager.fileExistsAtPath(path) == false {
            do {
                try self.fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog("Could not create directory at path:\(path) because of the following error: \(error.debugDescription)")
            }
        }
    }

    private func registerIsWindowActiveMethod() {
        let isWindowActive: @convention(block) (String) -> Bool = { tabId in
            return self.isTabActive(Int(tabId))
        }
        context.setObject(unsafeBitCast(isWindowActive, AnyObject.self), forKeyedSubscript: "_nativeIsWindowActive")
    }

    private func registerSendTelemetryMethod() {
        let sendTelemetry: @convention(block) (String) -> () = { telemetry in
            guard let data = telemetry.dataUsingEncoding(NSUTF8StringEncoding) else {
                return
            }
            do {
                let telemetrySignal =  try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
                
                let action = telemetrySignal!["action"] as! String
                if self.telemetryWhiteList.contains(action) {
                    let telemetryEvent = TelemetryLogEventType.JavaScriptSignal(telemetrySignal!)
                    TelemetryLogger.sharedInstance.logEvent(telemetryEvent)
                }
            } catch let error as NSError {
                Answers.logCustomEventWithName("[Anti-Trakcing] SendTelemetry Error", customAttributes: ["error": error])
            }
        }
        context.setObject(unsafeBitCast(sendTelemetry, AnyObject.self), forKeyedSubscript: "sendTelemetry")
    }

    private func registerHttpHandlerMethod() {
        let httpHandler: @convention(block) (String, String, JSValue, JSValue, Int, String) -> () = {[weak self] method, requestedUrl, callback, onerror, timeout, data in
			if let q = self?.dispatchQueue {
				dispatch_async(q) {
					if requestedUrl.startsWith("chrome://") {
						if let (fileName, fileExtension, directory) = self?.getFileMetaData(requestedUrl),
							path = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension, inDirectory: directory),
							content = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
							if content == "undefined" {
								onerror.callWithArguments(["Not Found"])
							} else {
								self?.httpHandlerReply(content, callback: callback, onerror: onerror)
							}
						} else {
								onerror.callWithArguments(["Not Found"])
						}
					} else {
						var hasError = false
                        if let isReachable = NetworkReachability.sharedInstance.isReachable where isReachable == false {
                            // No internet connection
                            hasError = true
                        } else if NetworkReachability.sharedInstance.isReachableViaWiFi() == false && self?.isWhitelistedUrl(requestedUrl) == false {
                            // do not download large files if user is not on WiFi
                            hasError = true
                        } else if method == "GET" {
							ConnectionManager.sharedInstance
								.sendRequest(.GET,
											 url: requestedUrl,
											 parameters: nil,
											 responseType: .StringResponse,
											 queue: q,
											 onSuccess: { responseData in
												self?.httpHandlerReply(responseData, callback: callback, onerror: onerror)
									},
											 onFailure: { (error) in
												onerror.callWithArguments(nil)
								})
							
						} else if method == "POST" {
							ConnectionManager.sharedInstance
								.sendPostRequestWithBody(requestedUrl,
														 body: data,
														 responseType: .StringResponse,
														 enableCompression: false, queue: (self?.dispatchQueue)!,
														 onSuccess: { responseData in
															self?.httpHandlerReply(responseData, callback: callback, onerror: onerror)
									},
														 onFailure: { (error) in
															onerror.callWithArguments(nil)
								})
						} else {
							hasError = true
						}
						if hasError {
							onerror.callWithArguments([])
						}
					}
				}
			} else {
				onerror.callWithArguments(nil)
			}
		}
        context.setObject(unsafeBitCast(httpHandler, AnyObject.self), forKeyedSubscript: "httpHandler")
    }

    private func httpHandlerReply(responseString: AnyObject, callback: JSValue, onerror: JSValue) {
        let response = ["status": 200, "responseText": responseString, "response": responseString]
        callback.callWithArguments([response])
	}

    private func getFileMetaData(requestedUrl: String) -> (String, String, String) {
        var fileName: String
        var fileExtension: String = "js" // default is js
        var directory: String
        var sourcePath = requestedUrl.replace("chrome://cliqz/content", replacement: "/modules")
        sourcePath = sourcePath.replace("/v8", replacement: "")

        if sourcePath.contains("/") {
            var pathComponents = sourcePath.componentsSeparatedByString("/")
            fileName = pathComponents.last!
            pathComponents.removeLast()
            directory = antiTrackingDirectory + pathComponents.joinWithSeparator("/")
        } else {
            fileName = sourcePath
            directory = antiTrackingDirectory
        }

        if fileName.contains(".") {
            let nameComponents = fileName.componentsSeparatedByString(".")
            fileName = nameComponents[0]
            fileExtension = nameComponents[1]
        }
        return (fileName, fileExtension, directory)
    }

    private func getRequestInfo(request: NSURLRequest) -> [String: AnyObject] {
        let url = request.URL?.absoluteString
        let userAgent = request.allHTTPHeaderFields?["User-Agent"]

        let isMainDocument = request.URL == request.mainDocumentURL
        let tabId = getTabId(userAgent)
        let isPrivate = false
        let originUrl = request.mainDocumentURL?.absoluteString

        var requestInfo = [String: AnyObject]()
        requestInfo["url"] = url
        requestInfo["method"] = request.HTTPMethod
        requestInfo["tabId"] = tabId ?? -1
        requestInfo["parentFrameId"] = -1
        // TODO: frameId how to calculate
        requestInfo["frameId"] = tabId ?? -1
        requestInfo["isPrivate"] = isPrivate
        requestInfo["originUrl"] = originUrl

        let contentPolicyType = ContentPolicyDetector.getContentPolicy(request, isMainDocument: isMainDocument)
        requestInfo["type"] = contentPolicyType;

        requestInfo["requestHeaders"] = request.allHTTPHeaderFields
        return requestInfo
    }

    private func isTabActive(tabId: Int?) -> Bool {
        return WebViewToUAMapper.idToWebView(tabId) != nil
    }

    private func getTabId(userAgent: String?) -> Int? {
        if let webView = WebViewToUAMapper.userAgentToWebview(userAgent) {
            return webView.uniqueId
        }
        return nil
    }

    private func getBlockResponseForRequest(requestInfo: [String: AnyObject]) -> [NSObject : AnyObject]? {

        if let requestInfoJsonString = toJSONString(requestInfo) {
            let onBeforeRequestCall = "System.get('platform/webrequest').default.onBeforeRequest._trigger(\(requestInfoJsonString));"
            let blockResponse = context.evaluateScript(onBeforeRequestCall).toDictionary()
            return blockResponse
        }
        return nil
    }
    
    private func isWhitelistedUrl(url: String) -> Bool {
        for whiteListUrl in urlsWhiteList {
            if url.startsWith(whiteListUrl) {
                return true
            }
        }
        return false
    }

	private func loadWindowTimers() {
		let w = WTWindowTimers(self.dispatchQueue)
		w.extend(context)
	}
}

