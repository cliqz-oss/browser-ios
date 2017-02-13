//
//  URLBarTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//


import XCTest
import KIF

class URLBarTest: KIFTestCase {
    
    func testAntiTrackingButton(){
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            tester.tapViewWithAccessibilityIdentifier("url")
        }
        tester.waitForViewWithAccessibilityLabel("Address and Search")
        XCTAssertFalse(tester.viewExistsWithLabel("AntiTrackingButton"), "AntiTracking Button is displayed, It shouldn't be displayed!")
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        XCTAssertTrue(tester.viewExistsWithLabel("AntiTrackingButton"), "AntiTracking Button is not displayed, It should be!")
        tester.tapViewWithAccessibilityLabel("Back")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testTabsChangeNumber() {
        showToolBar()
        let x = tester.waitForViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(x.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        XCTAssertTrue(tester.viewExistsWithLabel("Show Tabs"), "Show Tabs button should be on this View")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("Favorites")
        tester.waitForViewWithAccessibilityLabel("History")
        tester.waitForViewWithAccessibilityLabel("Tabs")
        tester.waitForViewWithAccessibilityLabel("+")
        tester.tapViewWithAccessibilityLabel("+")
        XCTAssertTrue(x.accessibilityValue == "2", "Less than two or more than two tabs are open, Two tabs should be opened!")
        showToolBar()
        resetApp(["New Tab, Most visited sites and News"])
    }
    
}
