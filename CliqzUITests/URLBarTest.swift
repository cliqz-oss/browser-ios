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
            if tester.viewExistsWithLabel("Address and Search"){
                tester.tapView(withAccessibilityLabel: "Address and Search")
            }
            else{
                tester.tapView(withAccessibilityIdentifier: "url")
            }
        }
        tester.waitForView(withAccessibilityLabel: "Address and Search")
        XCTAssertFalse(tester.viewExistsWithLabel("AntiTrackingButton"), "AntiTracking Button is displayed, It shouldn't be displayed!")
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.waitForView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        XCTAssertTrue(tester.viewExistsWithLabel("AntiTrackingButton"), "AntiTracking Button is not displayed, It should be!")
        tester.tapView(withAccessibilityLabel: "Back")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testTabsChangeNumber() {
        showToolBar()
        let x = tester.waitForView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(x?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        XCTAssertTrue(tester.viewExistsWithLabel("Show Tabs"), "Show Tabs button should be on this View")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.waitForView(withAccessibilityLabel: "Favorites")
        tester.waitForView(withAccessibilityLabel: "History")
        tester.waitForView(withAccessibilityLabel: "Tabs")
        tester.waitForView(withAccessibilityLabel: "+")
        tester.tapView(withAccessibilityLabel: "+")
        showToolBar()
        XCTAssertTrue(x?.accessibilityValue == "2", "Less than two or more than two tabs are open, Two tabs should be opened!")
        
        resetApp(["New Tab, Most visited sites and News","New Tab, Most visited sites and News"])
    }
    
}
