/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers

/// Handles requests to /about/sessionrestore to restore session history.
struct SessionRestoreHandler {
    
    private static let SessionRestorePath = "/about/sessionrestore"
    
    static func register(webServer: WebServer) {
        // Register the handler that accepts /about/sessionrestore?history=...&currentpage=... requests.
        webServer.registerHandlerForMethod("GET", module: "about", resource: "sessionrestore") { _ in
            if let sessionRestorePath = NSBundle.mainBundle().pathForResource("SessionRestore", ofType: "html") {
                do {
                    let sessionRestoreString = try String(contentsOfFile: sessionRestorePath)
                    return GCDWebServerDataResponse(HTML: sessionRestoreString)
                } catch _ {}
            }

            return GCDWebServerResponse(statusCode: 404)
        }
    }
    
    static func isRestorePageURL(url: NSURL?) -> Bool {
        if let scheme = url?.scheme, host = url?.host, path = url?.path {
            if scheme == "http" && host == "localhost" && path.startsWith(SessionRestorePath) {
                return true
            }
        }
        return false
    }
}
