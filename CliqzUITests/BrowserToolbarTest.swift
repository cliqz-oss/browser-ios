//
//  BrowserToolbarTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import KIF

class BrowserToolbarTest: KIFTestCase {
   

    func testToolBarOnSearchPage(){
        showToolBar()
        let back = tester.waitForViewWithAccessibilityLabel("Back")as! UIButton
        let forward = tester.waitForViewWithAccessibilityLabel("Forward")as! UIButton
        let share = tester.waitForViewWithAccessibilityLabel("Share")as! UIButton
        let bookmark = tester.waitForViewWithAccessibilityLabel("Bookmark")as! UIButton
        let showtabs = tester.waitForViewWithAccessibilityLabel("Show Tabs")as! UIButton
        XCTAssertFalse(back.enabled, "Back button should be Disabled")
        XCTAssertFalse(forward.enabled, "Forward button should be Disabled")
        XCTAssertFalse(share.enabled,"Share button should be Disabled")
        XCTAssertFalse(bookmark.enabled, "Bookmark button should be Disabled")
        XCTAssertTrue(showtabs.enabled, "Show Tabs button should be Enabled")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("New Tab, Most visited sites and News")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
        tester.tapViewWithAccessibilityIdentifier("url")
    }
    
    func testToolBarOnWebpage(){
        openTestWebPage()
        let back = tester.waitForViewWithAccessibilityLabel("Back")as! UIButton
        let forward = tester.waitForViewWithAccessibilityLabel("Forward")as! UIButton
        let share = tester.waitForViewWithAccessibilityLabel("Share")as! UIButton
        let bookmark = tester.waitForViewWithAccessibilityLabel("Bookmark")as! UIButton
        let showtabs = tester.waitForViewWithAccessibilityLabel("Show Tabs")as! UIButton
        XCTAssertTrue(back.enabled, "Back button should be enabled")
        XCTAssertFalse(forward.enabled, "Forward button should be Disabled")
        XCTAssertTrue(share.enabled, "Share button should be enabled")
        XCTAssertTrue(bookmark.enabled, "Bookmark button should be enabled")
        XCTAssertTrue(showtabs.enabled, "Show Tabs button should be enabled")
        tester.tapViewWithAccessibilityLabel("Back")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
    func testForwardButton(){
        openTestWebPage()
        gotToLinkInWebPage()
        tester.tapViewWithAccessibilityLabel("Back")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("Forward")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.waitForViewWithAccessibilityLabel("New Tab")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }
    
    func testForwardBackwardButtons(){
        openTestWebPage()
        let back = tester.waitForViewWithAccessibilityLabel("Back")as! UIButton
        let forward = tester.waitForViewWithAccessibilityLabel("Forward")as! UIButton
        XCTAssertTrue(back.enabled, "Back button should be enabled")
        XCTAssertFalse(forward.enabled, "Forward button should be Disabled")
        tester.tapViewWithAccessibilityLabel("Back")
        XCTAssertFalse(back.enabled, "Back button should be Disabled")
        XCTAssertTrue(forward.enabled, "Forward button should be Enabled")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("New Tab")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }
    
    func testForgetModeColor(){
        showToolBar()
        tester.longPressViewWithAccessibilityLabel("Show Tabs", duration: 1)
        tester.tapViewWithAccessibilityLabel("Open New Forget Tab")
        tester.waitForWebViewElementWithAccessibilityLabel("Forget Tab")
        tester.tapViewWithAccessibilityIdentifier("url")
        if let x = tester.waitForWebViewElementWithAccessibilityLabel("Forget Tab") as? UITextView {
            let expectedColor =  UIColor(colorLiteralRed: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            XCTAssertTrue(x.backgroundColor!.description == expectedColor.description, "Forget Mode Color is wrong, it should be \(expectedColor.description) isntead of \(x.backgroundColor!.description)")
        }
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
}
