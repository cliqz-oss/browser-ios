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
        tester.wait(forTimeInterval: 2)
    
        XCTAssertTrue(tester.viewExistsWithLabel("topSites"), "Top Sites are not shown on this view")
        XCTAssertTrue(tester.viewExistsWithLabel("topNews"), "Top New is not displayed on this view")
    }

    func testFreshTabOnOpeningEmptyTabFromTabsManager() {
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.waitForView(withAccessibilityLabel: "New Tab, Most visited sites and News")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        tester.wait(forTimeInterval: 2)
        XCTAssertTrue(tester.viewExistsWithLabel("topSites"), "Top Sites are not shown on this view")
        XCTAssertTrue(tester.viewExistsWithLabel("topNews"), "Top New is not displayed on this view")
    }
    
}
