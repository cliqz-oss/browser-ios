//
//  NavigationExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 12/31/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

extension WebServer {

    /// Convenience method to register a folder in the main bundle.
    func registerMainBundlePath(basePath: String, directoryPath: String) {
        server.addGETHandlerForBasePath(basePath, directoryPath: directoryPath, indexFilename:nil, cacheAge:3600, allowRangeRequests:true)
    }
}

class NavigationExtension: NSObject {
    // if true FireFox server will be used to host the navigation extension, else new local web server will be started to host the navigation extension
    static let useFireFoxServer = true
    
    // the port for the local web server if used
    static let localServerPort: in_port_t = 3005


    // base url for all resoruces
    static let baseURL: String = {
        if useFireFoxServer {
            let server = WebServer.sharedInstance
            return "\(server.base)/extension"
        } else {
            return "http://localhost:\(localServerPort)/extension"
        }
    }()
    
    // url for index page
    static let indexURL: String =  {
        return "\(baseURL)/index.html"
    }()

    // url for history page
    static let historyURL: String =  {
        return "\(baseURL)/history.html"
    }()
    
    // url for fresh tab page
    static let freshtabURL: String =  {
        return "\(baseURL)/freshtab.html"
    }()
    
    
    // starting navigation extension either by hosting it to the same server that FireFox uses or start new webserver
    class func start() {
        if AppStatus.sharedInstance.isDebug {
            if useFireFoxServer {
                registerNavigationExtensionOnFireFoxServer()
            } else {
                startLocalServer()
            }
        }
    }
    
    
    // using the same server that Firefox have to make the navigation extension works locally
    private class func registerNavigationExtensionOnFireFoxServer() {
        let bundlePath = NSBundle.mainBundle().bundlePath
        let extensionPath = bundlePath + "/" + "search"
        
        let server = WebServer.sharedInstance
        server.registerMainBundlePath("/extension/", directoryPath: extensionPath)
    }
    
    
    // starting new local web server to host the navigation extension
    private class func startLocalServer() {
        let bundlePath = NSBundle.mainBundle().bundlePath
        let extensionPath = bundlePath + "/" + "search"
        
        let httpServer = HttpServer()
        httpServer["/extension/(.+)"] = HttpHandlers.directory(extensionPath)
        
        httpServer["/myproxy"] = { (request: HttpRequest) in
            let u: String = request.urlParams[0].1
            let data = NSData(contentsOfURL: NSURL(string:u)!)
            return HttpResponse.RAW(200, data!)
        }
        httpServer.start(localServerPort)
        
    }
}
