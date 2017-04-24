//
//  TabsManagerTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import KIF


class TabsManagerTest: KIFTestCase {

    func testTabRemoval() {
        openWebPage("http://cliqz.com/")
        tester.waitForTimeInterval(1)
        showToolBar()
        resetApp(["https://cliqz.com/"])
    }

    func testBackButton() {
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        goToLinkInWebPage()
        tester.tapViewWithAccessibilityLabel("Back")
        XCTAssertTrue(tester.viewExistsWithLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html"), "The initial webpage that was opened is not displayed, It should be!")
        resetApp(["https://cdn.cliqz.com/mobile/browser/tests/forward_test.html"])
        
    }

}
