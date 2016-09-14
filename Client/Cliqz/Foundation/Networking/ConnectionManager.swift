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
    
    internal func sendGetRequest(url: String, parameters: [String: AnyObject]?, responseType: ResponseType, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        switch responseType {
        case .JSONResponse:
            Alamofire.request(.GET, url, parameters: parameters)
                .responseJSON {
                    request, response, result in
                    switch result {
                        
                    case .Success(let json):
                        onSuccess(json)
                        
                    case .Failure(let data, let error):
                        onFailure(data, error)
                    }
            }
        case .StringResponse:
            Alamofire.request(.GET, url, parameters: parameters)
                .responseString {
                    request, response, result in
                    switch result {
                        
                    case .Success(let string):
                        onSuccess(string)
                        
                    case .Failure(let data, let error):
                        onFailure(data, error)
                    }
            }
        }
        
    }
    
    
    internal func sendPostRequest(url: String, parameters: [String: AnyObject], responseType: ResponseType, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        switch responseType {
        case .JSONResponse:
            Alamofire.request(.POST, url, parameters: parameters)
                .responseJSON {
                    request, response, result in
                    switch result {
                        
                    case .Success(let json):
                        onSuccess(json)
                        
                    case .Failure(let data, let error):
                        onFailure(data, error)
                    }
            }
        case .StringResponse:
            Alamofire.request(.POST, url, parameters: parameters)
                .responseString {
                    request, response, result in
                    switch result {
                        
                    case .Success(let string):
                        onSuccess(string)
                        
                    case .Failure(let data, let error):
                        onFailure(data, error)
                    }
            }
        }
    }
    
    
    internal func sendPostRequest(url: String, body: AnyObject, responseType: ResponseType, enableCompression: Bool, onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
        
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
                        .responseJSON {
                            request, response, result in
                            switch result {
                                
                            case .Success(let json):
                                onSuccess(json)
                                
                            case .Failure(let data, let error):
                                onFailure(data, error)
                            }
                    }
                case .StringResponse:
                    Alamofire.request(request)
                        .responseString {
                            request, response, result in
                            switch result {
                                
                            case .Success(let string):
                                onSuccess(string)
                                
                            case .Failure(let data, let error):
                                onFailure(data, error)
                            }
                    }
                }
            } catch let error as NSError {
                Answers.logCustomEventWithName("sendPostRequestError", customAttributes: ["error": error.localizedDescription])
            }
        } else {
            Answers.logCustomEventWithName("sendPostRequestError", customAttributes: nil)
        }
        
    }
}
