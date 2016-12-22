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
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            tester.tapViewWithAccessibilityIdentifier("url")
        }
        tester.waitForFirstResponderWithAccessibilityLabel("Address and Search")
        tester.waitForTimeInterval(1)
        tester.setText("cliqz.com", intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
        }
        tester.waitForTimeInterval(2)
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("http://cliqz.com/")
        tester.swipeViewWithAccessibilityLabel("http://cliqz.com/", inDirection: KIFSwipeDirection.Left)
        tester.waitForTimeInterval(1)
        tester.waitForViewWithAccessibilityLabel("New Tab")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
        if tester.viewExistsWithLabel("Go"){
        }
        else{
        tester.tapViewWithAccessibilityIdentifier("url")
        }
    }

    func testBackButton() {
        openTestWebPage()
        gotToLinkInWebPage()
        tester.tapViewWithAccessibilityLabel("Back")
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("Back")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("New Tab, Most visited sites and News", inDirection: KIFSwipeDirection.Left)
        tester.waitForViewWithAccessibilityLabel("New Tab")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            tester.tapViewWithAccessibilityIdentifier("url")
        }
        
    }

}
