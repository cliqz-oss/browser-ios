//
//  ConnectionManager.swift
//  Client
//
//  Created by Mahmoud Adam on 11/4/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Alamofire
import Crashlytics

enum ResponseType {
    case JSONResponse
    case StringResponse
}

class ConnectionManager {
    
    //MARK: - Singltone
    static let sharedInstance = ConnectionManager()
    private init() {
        
    }
    
    //MARK: - Sending Requests
	internal func sendRequest(method: Alamofire.Method, url: String, parameters: [String: AnyObject]?, responseType: ResponseType, queue: dispatch_queue_t, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {

        switch responseType {
            
        case .JSONResponse:
            Alamofire.request(method, url, parameters: parameters)
                .responseJSON(queue: queue) {
                    response in
                    self.handelJSONResponse(response, onSuccess: onSuccess, onFailure: onFailure)
            }
        case .StringResponse:
            Alamofire.request(method, url, parameters: parameters)
				.responseString(queue: queue) {
                    response in
                    self.handelStringResponse(response, onSuccess: onSuccess, onFailure: onFailure)
            }
        }
    }
    
	internal func sendPostRequestWithBody(url: String, body: AnyObject, responseType: ResponseType, enableCompression: Bool, queue: dispatch_queue_t, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        
        if NSJSONSerialization.isValidJSONObject(body) {
            do {
                let request = NSMutableURLRequest(URL: NSURL(string: url)!)
                request.HTTPMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let data = try NSJSONSerialization.dataWithJSONObject(body, options: [])

                if (enableCompression) {
                    request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
                    let compressedData : NSData = try data.gzippedData()
                    request.HTTPBody = compressedData
                } else {
                    request.HTTPBody = data
                }
                
                switch responseType {
                case .JSONResponse:
                    Alamofire.request(request)
                        .responseJSON(queue: queue) {
                            response in
                            self.handelJSONResponse(response, onSuccess: onSuccess, onFailure: onFailure)
                    }
                case .StringResponse:
                    Alamofire.request(request)
                        .responseString(queue: queue) {
                            response in
                            self.handelStringResponse(response, onSuccess: onSuccess, onFailure: onFailure)
                    }
                }
            } catch let error as NSError {
                Answers.logCustomEventWithName("sendPostRequestError", customAttributes: ["error": error.localizedDescription])
            }
        } else {
            Answers.logCustomEventWithName("sendPostRequestError", customAttributes: nil)
        }
        
    }
    
    // MARK: - Private methods
    
    private func handelStringResponse(response: Alamofire.Response<String, NSError>, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        
        switch response.result {
            
        case .Success(let string):
            onSuccess(string)
            
        case .Failure(let error):
            onFailure(response.data, error)
        }
    }
    
    private func handelJSONResponse(response: Alamofire.Response<AnyObject, NSError>, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        
        switch response.result {
            
        case .Success(let json):
            onSuccess(json)
            
        case .Failure(let error):
            onFailure(response.data, error)
        }
    }
}
