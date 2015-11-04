//
//  ConnectionManager.swift
//  Client
//
//  Created by Mahmoud Adam on 11/4/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation
import Alamofire

class ConnectionManager {
    
    //MARK: - Singltone
    static let sharedInstance = ConnectionManager()
    private init() {
        
    }
    
    //MARK: - Sending Requests
    
    internal func sendGetRequest(url: String, parameters: [String: AnyObject], onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
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
    }
    
    internal func sendPostRequest(url: String, parameters: [String: AnyObject], onSuccess: AnyObject -> (), onFailure:(NSData?, ErrorType) -> ()) {
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
    }
}
