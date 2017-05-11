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
    func registerMainBundlePath(_ basePath: String, directoryPath: String) {
        server.addGETHandler(forBasePath: basePath, directoryPath: directoryPath, indexFilename:nil, cacheAge:0, allowRangeRequests:true)
    }
}

class NavigationExtension: NSObject {
    
    // the port for the local web server if used
    static let localServerPort: in_port_t = 3005


    // base url for all resoruces
    static let baseURL: String = {
        let server = WebServer.sharedInstance
        return "\(server.base)/extension"
    }()
    
    // url for index page
    static let indexURL: String =  {
        return "\(baseURL)/index.html"
    }()

    // url for history page
    static let historyURL: String =  {
        return "\(baseURL)/history.html"
    }()

	// url for favorites page
	static let favoritesURL: String =  {
		return "\(baseURL)/favorites.html"
	}()

    // url for fresh tab page
    static let freshtabURL: String =  {
        return "\(baseURL)/freshtab.html"
    }()
    
    // starting navigation extension either by hosting it to the same server that FireFox uses or start new webserver
    class func start() {
        registerNavigationExtensionOnFireFoxServer()
    }

    // using the same server that Firefox have to make the navigation extension works locally
    fileprivate class func registerNavigationExtensionOnFireFoxServer() {
        let bundlePath = Bundle.main.bundlePath
        let extensionPath = bundlePath + "/" + "Extension/build/mobile/search"
        
        let server = WebServer.sharedInstance
        server.registerMainBundlePath("/extension/", directoryPath: extensionPath)
    }
}
