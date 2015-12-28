//
//  ConfigurationManager.swift
//  Client
//
//  Created by Mahmoud Adam on 12/23/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

class ConfigurationManager: NSObject {
    
    //MARK: - Singltone & init
    static let sharedInstance = ConfigurationManager()
    
    //MARK: - WKWebView Configuration
    private lazy var sharedConfig = WKWebViewConfiguration()
    
    func getSharedConfiguration(scriptMessageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        
        let controller = WKUserContentController()
        controller.addScriptMessageHandler(scriptMessageHandler, name: "jsBridge")

        sharedConfig.userContentController = controller
        return sharedConfig
    }
}
