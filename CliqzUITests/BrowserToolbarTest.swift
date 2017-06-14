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
        }
        super.tearDown()
    }
 
    func testToolBarStatusOnSearchPage(){
        showToolBar()
        let back = tester.waitForView(withAccessibilityLabel: "Back")as! UIButton
        let forward = tester.waitForView(withAccessibilityLabel: "Forward")as! UIButton
        let share = tester.waitForView(withAccessibilityLabel: "Share")as! UIButton
        let bookmark = tester.waitForView(withAccessibilityLabel: "Bookmark")as! UIButton
        let showtabs = tester.waitForView(withAccessibilityLabel: "Show Tabs")as! UIButton
        XCTAssertFalse(back.isEnabled, "Back button should be Disabled")
        XCTAssertFalse(forward.isEnabled, "Forward button should be Disabled")
        XCTAssertFalse(share.isEnabled,"Share button should be Disabled")
        XCTAssertFalse(bookmark.isEnabled, "Bookmark button should be Disabled")
        XCTAssertTrue(showtabs.isEnabled, "Show Tabs button should be Enabled")
        resetApp(["New Tab, Most visited sites and News"])
        
    }
    
    func testToolBarStatusOnWebpage(){
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        let back = tester.waitForView(withAccessibilityLabel: "Back")as! UIButton
        let forward = tester.waitForView(withAccessibilityLabel: "Forward")as! UIButton
        let share = tester.waitForView(withAccessibilityLabel: "Share")as! UIButton
        let bookmark = tester.waitForView(withAccessibilityLabel: "Bookmark")as! UIButton
        let showtabs = tester.waitForView(withAccessibilityLabel: "Show Tabs")as! UIButton
        XCTAssertTrue(back.isEnabled, "Back button should be enabled")
        XCTAssertFalse(forward.isEnabled, "Forward button should be Disabled")
        XCTAssertTrue(share.isEnabled, "Share button should be enabled")
        XCTAssertTrue(bookmark.isEnabled, "Bookmark button should be enabled")
        XCTAssertTrue(showtabs.isEnabled, "Show Tabs button should be enabled")
        tester.tapView(withAccessibilityLabel: "Back")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testForwardButton(){
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        goToLinkInWebPage()
        tester.tapView(withAccessibilityLabel: "Back")
        tester.waitForView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapView(withAccessibilityLabel: "Forward")
        tester.waitForView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
         resetApp(["https://cdn.cliqz.com/mobile/browser/tests/testpage.html"])
    }
    
    func testForwardBackwardButtons(){
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/testpage.html")
        let back = tester.waitForView(withAccessibilityLabel: "Back")as! UIButton
        let forward = tester.waitForView(withAccessibilityLabel: "Forward")as! UIButton
        XCTAssertTrue(back.isEnabled, "Back button should be enabled")
        XCTAssertFalse(forward.isEnabled, "Forward button should be Disabled")
        tester.tapView(withAccessibilityLabel: "Back")
        XCTAssertFalse(back.isEnabled, "Back button should be Disabled")
        XCTAssertTrue(forward.isEnabled, "Forward button should be Enabled")
        resetApp(["New Tab, Most visited sites and News"])
    }
    
    func testForgetTab(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressView(withAccessibilityLabel: "Show Tabs", duration: 1)
        tester.tapView(withAccessibilityLabel: "Open New Forget Tab")
        tester.waitForView(withAccessibilityLabel: "Forget Tab")
        let darkview = tester.waitForView(withAccessibilityLabel: "Forget Mode Background")
        XCTAssertEqual(darkview?.backgroundColor, UIColor.gray,"View is not expected color it is\(darkview?.backgroundColor) ")
        resetApp(["New Tab, Most visited sites and News", "New Tab, Most visited sites and News"])
    }
    
    func testForgetTabInTabsOVerview(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.longPressView(withAccessibilityLabel: "+", duration: 1)
        tester.tapView(withAccessibilityLabel: "Open New Forget Tab")
        tester.waitForView(withAccessibilityLabel: "Forget Tab")
        let darkview = tester.waitForView(withAccessibilityLabel: "Forget Mode Background")
        XCTAssertEqual(darkview?.backgroundColor, UIColor.gray, "View is not expected color it is\(darkview?.backgroundColor) ")
        resetApp(["New Tab, Most visited sites and News", "New Tab, Most visited sites and News"])
    }
    func testForgetTabDeletionSwipeLeft(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressView(withAccessibilityLabel: "Show Tabs", duration: 1)
        tester.tapView(withAccessibilityLabel: "Open New Forget Tab")
        tester.waitForView(withAccessibilityLabel: "Forget Tab")
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.swipeView(withAccessibilityLabel: "New Tab, Most visited sites and News", in: KIFSwipeDirection.left)
    }
    
    func testForgetTabDeletionSwipeRight(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.longPressView(withAccessibilityLabel: "Show Tabs", duration: 1)
        tester.tapView(withAccessibilityLabel: "Open New Forget Tab")
        tester.waitForView(withAccessibilityLabel: "Forget Tab")
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.swipeView(withAccessibilityLabel: "New Tab, Most visited sites and News", in: KIFSwipeDirection.right)
    }

    
    func testInitialTabCount(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        let showTabs = tester.waitForView(withAccessibilityLabel: "Show Tabs")as! UIButton
        XCTAssertTrue(showTabs.accessibilityValue == "1", "Initial tab count is not one, it should be!")
    }

}
