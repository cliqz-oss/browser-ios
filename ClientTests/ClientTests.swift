/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit

class ClientTests: XCTestCase {

    func testSyncUA() {
        let ua = UserAgent.syncUserAgent
        let loc = ua.rangeOfString("^Firefox-iOS-Sync/[0-9\\.]+ \\([-_A-Za-z0-9= \\(\\)]+\\)$", options: NSStringCompareOptions.RegularExpressionSearch)
        XCTAssertTrue(loc != nil, "Sync UA is as expected. Was \(ua)")
    }

    // Simple test to make sure the WKWebView UA matches the expected FxiOS pattern.
    func testUserAgent() {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String

        let compare: String -> Bool = { ua in
            let range = ua.rangeOfString("^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) FxiOS/\(appVersion) Mobile/[A-Za-z0-9]+ Safari/[0-9\\.]+$", options: NSStringCompareOptions.RegularExpressionSearch)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.defaultUserAgent()), "User agent computes correctly.")
        XCTAssertTrue(compare(UserAgent.cachedUserAgent(checkiOSVersion: true)!), "User agent is cached correctly.")

        let expectation = expectationWithDescription("Found Firefox user agent")

        let webView = WKWebView()
        webView.evaluateJavaScript("navigator.userAgent") { result, error in
            let userAgent = result as! String
            if compare(userAgent) {
                expectation.fulfill()
            } else {
                XCTFail("User agent did not match expected pattern! \(userAgent)")
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDesktopUserAgent() {
        let compare: String -> Bool = { ua in
            let range = ua.rangeOfString("^Mozilla/5\\.0 \\(Macintosh; Intel Mac OS X [0-9_]+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) Safari/[0-9\\.]+$", options: NSStringCompareOptions.RegularExpressionSearch)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
    }
}
