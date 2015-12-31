//
//  NavigationExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 12/31/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

class NavigationExtension: NSObject {
    static let baseURL: String = {
        if AppStatus.sharedInstance.isDebug {
            return "http://localhost:3005/extension" // Debug
        } else if AppStatus.sharedInstance.isRelease {
            return "http://cdn.cliqz.com/mobile/extension" // Release
        } else {
            return "http://cdn.cliqz.com/mobile/beta" // TestFlight
        }
    }()
    
    static let indexURL: String =  {
        return "\(baseURL)/index.html"
    }()
    
    static let historyURL: String =  {
        return "\(baseURL)/history.html"
    }()
    
    static let freshtabURL: String =  {
        return "\(baseURL)/freshtab.html"
    }()
    
    
    class func start() {
        startNavigationExtensionLocalServer()
    }
    
    // Cliqz: starting the navigation extension inside a local server
    private class func startNavigationExtensionLocalServer() {
        let bundlePath = NSBundle.mainBundle().bundlePath
        let extensionPath = bundlePath + "/" + "search"
        
        let httpServer = HttpServer()
        httpServer["/extension/(.+)"] = HttpHandlers.directory(extensionPath)
        
        httpServer["/myproxy"] = { (request: HttpRequest) in
            let u: String = request.urlParams[0].1
            let data = NSData(contentsOfURL: NSURL(string:u)!)
            return HttpResponse.RAW(200, data!)
        }
        httpServer.start(3005)
        
    }
}
