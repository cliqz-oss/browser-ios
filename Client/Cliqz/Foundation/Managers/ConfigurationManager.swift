//
//  ConfigurationManager.swift
//  Client
//
//  Created by Mahmoud Adam on 12/23/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import WebKit

class ConfigurationManager: NSObject {
    
    //MARK: - Singltone & init
    static let sharedInstance = ConfigurationManager()
    
    //MARK: - WKWebView Configuration
    fileprivate lazy var sharedConfig = WKWebViewConfiguration()
    
    func getSharedConfiguration(_ scriptMessageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        
        let controller = WKUserContentController()
        controller.add(LeakAvoider(delegate:scriptMessageHandler), name: "jsBridge")

        sharedConfig.userContentController = controller
        return sharedConfig
    }
}
