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
    override func tearDown() {
        if tester.viewExistsWithLabel("Back to safe site"){
            tester.tapViewWithAccessibilityLabel("Back to safe site")
        }
        if tester.viewExistsWithLabel("Settings"){
            tester.tapViewWithAccessibilityLabel("Settings")
        }
        if tester.viewExistsWithLabel("Done"){
            tester.tapViewWithAccessibilityLabel("Done")
        }
        if tester.viewExistsWithLabel("cliqzBack"){
            tester.tapViewWithAccessibilityLabel("closeTab")
        }
        super.tearDown()
    }
 
    func testToolBarStatusOnSearchPage(){
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
        resetApp(["New Tab, Most visited sites and News"])
        
    }
    
    func testToolBarStatusOnWebpage(){
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
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
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testForwardButton(){
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        goToLinkInWebPage()
        tester.tapViewWithAccessibilityLabel("Back")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("Forward")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
         resetApp(["https://cdn.cliqz.com/mobile/browser/tests/testpage.html"])
    }
    
    func testForwardBackwardButtons(){
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
        let back = tester.waitForViewWithAccessibilityLabel("Back")as! UIButton
        let forward = tester.waitForViewWithAccessibilityLabel("Forward")as! UIButton
        XCTAssertTrue(back.enabled, "Back button should be enabled")
        XCTAssertFalse(forward.enabled, "Forward button should be Disabled")
        tester.tapViewWithAccessibilityLabel("Back")
        XCTAssertFalse(back.enabled, "Back button should be Disabled")
        XCTAssertTrue(forward.enabled, "Forward button should be Enabled")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testForgetTab(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressViewWithAccessibilityLabel("Show Tabs", duration: 1)
        tester.tapViewWithAccessibilityLabel("Open New Forget Tab")
        tester.waitForViewWithAccessibilityLabel("Forget Tab")
        let darkview = tester.waitForViewWithAccessibilityLabel("Forget Mode Background")
        XCTAssertEqual(darkview.backgroundColor, UIColor.grayColor(),"View is not expected color it is\(darkview.backgroundColor) ")
        resetApp(["New Tab, Most visited sites and News", "New Tab, Most visited sites and News"])
    }
    
    func testForgetTabInTabsOVerview(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.longPressViewWithAccessibilityLabel("+", duration: 1)
        tester.tapViewWithAccessibilityLabel("Open New Forget Tab")
        tester.waitForViewWithAccessibilityLabel("Forget Tab")
        let darkview = tester.waitForViewWithAccessibilityLabel("Forget Mode Background")
        XCTAssertEqual(darkview.backgroundColor, UIColor.grayColor(),"View is not expected color it is\(darkview.backgroundColor) ")
        resetApp(["New Tab, Most visited sites and News", "New Tab, Most visited sites and News"])
    }
    func testForgetTabDeletionSwipeLeft(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressViewWithAccessibilityLabel("Show Tabs", duration: 1)
        tester.tapViewWithAccessibilityLabel("Open New Forget Tab")
        tester.waitForViewWithAccessibilityLabel("Forget Tab")
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
    }
    
    func testForgetTabDeletionSwipeRight(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressViewWithAccessibilityLabel("Show Tabs", duration: 1)
        tester.tapViewWithAccessibilityLabel("Open New Forget Tab")
        tester.waitForViewWithAccessibilityLabel("Forget Tab")
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Right)
    }

    
    func testInitialTabCount(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        let showTabs = tester.waitForViewWithAccessibilityLabel("Show Tabs")as! UIButton
        XCTAssertTrue(showTabs.accessibilityValue == "1", "Initial tab count is not one, it should be!")
    }

}
