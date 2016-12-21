//
//  FreshTabTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/20/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import KIF


class FreshTabTest: KIFTestCase {

    func testFreshTabInitialState() {
        tester.waitForTimeInterval(2)
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("startingpoint"), "FreshTab is not loaaded")
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("topSites"), "Top Sites are not shown on this view")
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("topNews"), "Top New is not displayed on this view")
    }

    func testFreshTabOnOpeningEmptyTabFromTabsManager() {
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("New Tab")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(2)
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("startingpoint"), "FreshTab is not loaaded")
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("topSites"), "Top Sites are not shown on this view")
        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("topNews"), "Top New is not displayed on this view")
    }
    
}
