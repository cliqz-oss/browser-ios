//
//  ShareCardHelper.swift
//  Client
//
//  Created by Mahmoud Adam on 7/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import GCDWebServers

class ShareCardHelper: NSObject {
    var currentCard: String?
    var currentCardTitle: String?
    
    static let shareCardURL: URL? =  { URL(string: "\(WebServer.sharedInstance.base)/share/card") }()
    static let sharedInstance = ShareCardHelper()
    
    static func register(_ webServer: WebServer) {
        
        // Register the handler that accepts /share/card
        webServer.registerHandlerForMethod("GET", module: "share", resource: "card") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let html = sharedInstance.currentCard,
                let response = GCDWebServerDataResponse(html: html) {
                return response
            }
            
            return GCDWebServerDataResponse(html: "") // TODO Needs a proper error page
        }
    }
    
    
}
