//
//  XMLHttpRequest.swift
//  Client
//
//  Created by Sahakyan on 6/23/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore
import Alamofire

enum ReadyState: Int {
	case Unsent = 0		// open()has not been called yet.
	case Opened			// send()has not been called yet.
	case Headers		// RECEIVED	send() has been called, and headers and status are available.
	case Loading		// Downloading; responseText holds partial data.
	case Done			// The operation is complete.
}

@objc protocol XMLHttpRequestProtocol: JSExport {
	
	var responseText: NSString? { get set }
	var onreadystatechange: JSValue? { get set }
	var onload: JSValue? { get set }
	var onerror: JSValue? { get set }
	var status: NSNumber? { get set }
	var readyState: NSNumber? { get set }

	func open(method: NSString, _ url: NSString, _ async: Bool)
	func send(data: AnyObject?)
	func setRequestHeader(name: String, _ value: String)

}

@objc class XMLHttpRequest: NSObject, XMLHttpRequestProtocol {

	dynamic var responseText: NSString?
	dynamic var onreadystatechange: JSValue?
	dynamic var onload: JSValue?
	dynamic var onerror: JSValue?
	dynamic var status: NSNumber?
	dynamic var readyState: NSNumber?
	
	var httpMethod: String?
	var url: NSURL?
	var async: Bool
	var requestHeaders: [String: String]?
	var responseHeaders: NSDictionary?
	
	override init() {
		async = true
		readyState = NSNumber(long: ReadyState.Unsent.rawValue)
		requestHeaders = [String: String]()
		super.init()
	}

	func extendJSContext(jsContext: JSContext) {
		let simplifyString: @convention(block) () -> XMLHttpRequest = { () in
			return self
		}
		jsContext.setObject(unsafeBitCast(simplifyString, AnyObject.self), forKeyedSubscript: "XMLHttpRequest")
	}

	func open(method: NSString, _ url: NSString, _ async: Bool) {
		self.httpMethod = method as String
		self.url = NSURL(string: url as String)!
		self.async = async
		self.readyState = NSNumber(long: ReadyState.Opened.rawValue)
	}

	func send(data: AnyObject?) {
		Alamofire.request(.GET, self.url!.absoluteString!, headers: self.requestHeaders)
		.validate(statusCode: 200..<300)
		.response { [weak self] (responseRequest, responseResponse, responseData, responseError) in
			self?.status = responseResponse?.statusCode
			self?.readyState = NSNumber(long: ReadyState.Done.rawValue)
			self?.responseText = NSString(data: responseData!, encoding: NSUTF8StringEncoding)
			if (self?.onreadystatechange != nil) {
				self?.onreadystatechange!.callWithArguments([])
			}
		}
	}

	func setRequestHeader(name: String, _ value: String) {
		requestHeaders![name] = value
	}

}
