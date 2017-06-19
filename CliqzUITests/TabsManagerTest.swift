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
    override func tearDown() {
        if tester.viewExistsWithLabel("Back to safe site"){
            tester.tapView(withAccessibilityLabel: "Back to safe site")
        }
        if tester.viewExistsWithLabel("Settings"){
            tester.tapView(withAccessibilityLabel: "Settings")
        }
        if tester.viewExistsWithLabel("Done"){
            tester.tapView(withAccessibilityLabel: "Done")
        }
        if tester.viewExistsWithLabel("cliqzBack"){
            tester.tapView(withAccessibilityLabel: "closeTab")
            tester.tapView(withAccessibilityLabel: "cliqzBack")
        }
        super.tearDown()
    }
    
    func testTabRemoval() {
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
        tester.wait(forTimeInterval: 1)
        showToolBar()
        resetApp(["https://cdn.cliqz.com/mobile/browser/tests/testpage.html"])
    }

    func testBackButton() {
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        goToLinkInWebPage()
        tester.tapView(withAccessibilityLabel: "Back")
        XCTAssertTrue(tester.viewExistsWithLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html"), "The initial webpage that was opened is not displayed, It should be!")
        resetApp(["https://cdn.cliqz.com/mobile/browser/tests/forward_test.html"])
    }
    
    func testTabsManager(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("New Tab, Most visited sites and News"), "Tabs overview is not shown or New Tab is not shown. ")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
}
