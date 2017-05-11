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
	case unsent = 0		// open()has not been called yet.
	case opened			// send()has not been called yet.
	case headers		// RECEIVED	send() has been called, and headers and status are available.
	case loading		// Downloading; responseText holds partial data.
	case done			// The operation is complete.
}

@objc protocol XMLHttpRequestProtocol: JSExport {
	
	var responseText: NSString? { get set }
	var onreadystatechange: JSValue? { get set }
	var onload: JSValue? { get set }
	var onerror: JSValue? { get set }
	var status: NSNumber? { get set }
	var readyState: NSNumber? { get set }

	func open(_ method: NSString, _ url: NSString, _ async: Bool)
	func send(_ data: AnyObject?)
	func setRequestHeader(_ name: String, _ value: String)

}

@objc class XMLHttpRequest: NSObject, XMLHttpRequestProtocol {

	dynamic var responseText: NSString?
	dynamic var onreadystatechange: JSValue?
	dynamic var onload: JSValue?
	dynamic var onerror: JSValue?
	dynamic var status: NSNumber?
	dynamic var readyState: NSNumber?
	
	var httpMethod: String?
	var url: URL?
	var async: Bool
	var requestHeaders: [String: String]?
	var responseHeaders: NSDictionary?
	
	override init() {
		async = true
		readyState = NSNumber(value: ReadyState.unsent.rawValue as Int)
		requestHeaders = [String: String]()
		super.init()
	}

	func extendJSContext(_ jsContext: JSContext) {
		let simplifyString: @convention(block) () -> XMLHttpRequest = { () in
			return self
		}
		jsContext.setObject(unsafeBitCast(simplifyString, to: AnyObject.self), forKeyedSubscript: "XMLHttpRequest" as (NSCopying & NSObjectProtocol)!)
	}

	func open(_ method: NSString, _ url: NSString, _ async: Bool) {
		self.httpMethod = method as String
		self.url = URL(string: url as String)!
		self.async = async
		self.readyState = NSNumber(value: ReadyState.opened.rawValue as Int)
	}

	func send(_ data: AnyObject?) {
		Alamofire.request(self.url!.absoluteString, method: .get, headers: self.requestHeaders)
		.validate(statusCode: 200..<300)
		.response { [weak self] (response) in
			self?.status = response.response?.statusCode as! NSNumber
			self?.readyState = NSNumber(value: ReadyState.done.rawValue as Int)
			self?.responseText = NSString(data: response.data!, encoding: String.Encoding.utf8.rawValue)
			if (self?.onreadystatechange != nil) {
				self?.onreadystatechange!.call(withArguments: [])
			}
		}
	}

	func setRequestHeader(_ name: String, _ value: String) {
		requestHeaders![name] = value
	}

}
