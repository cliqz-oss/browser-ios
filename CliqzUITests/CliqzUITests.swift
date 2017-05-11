//
//  CliqzUITests.swift
//  CliqzUITests
//
//  Created by Sahakyan on 2/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import KIF


class CliqzUITests: KIFTestCase {

	func testSearchIsFirstResponder() {

		tester.waitForView(withAccessibilityLabel: NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns."))
		tester.enterText(intoCurrentFirstResponder: "Cliqz")
        tester.wait(forTimeInterval: 1)
        let searchBar = tester.waitForView(withAccessibilityLabel: "Address and Search")
        XCTAssertTrue((searchBar?.accessibilityValue!.startsWith("Cliqz"))!, "Search Bar is not Focused on Opening the application, It Should be!")
//        This code tests autocomplete
        tester.tapView(withAccessibilityLabel: "CliqzClear")
//        tester.tapViewWithAccessibilityLabel("urlExpand")
//        tester.tapViewWithAccessibilityLabel("Show Tabs")
//        tester.waitForViewWithAccessibilityLabel("New Tab")
//        tester.tapViewWithAccessibilityLabel("cliqzBack")
//        tester.waitForTimeInterval(5)
	}

    //    func testHistoryButton() {
    //		// Use recording to get started writing UI tests.
    ////		tester.waitForViewWithAccessibilityLabel("HistoryButton")
    ////		tester.tapViewWithAccessibilityLabel("HistoryButton")
    ////		XCTAssertTrue(tester.viewExistsWithLabel("CloseHistoryButton"))
    ////		tester.tapViewWithAccessibilityLabel("CloseHistoryButton")
    //	}

    //    func testHistoryTab(){
    //        tester.waitForSoftwareKeyboard()
    //        tester.waitForViewWithAccessibilityLabel("Show Tabs")
    //        tester.tapViewWithAccessibilityLabel("Show Tabs")
    //        tester.waitForViewWithAccessibilityLabel("History")
    //        tester.tapViewWithAccessibilityLabel("History")
    ////        tester.waitForWebViewElementWithAccessibilityLabel("nohistoryyet")
    ////        system.waitForTimeInterval(4)
    ////        system.waitForNotificationName("ExtensionIsReady", object: nil)
    ////        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("Her find"), "No element with cf answer")
    ////        tester.hasWebViewElementWithAccessibilityLabel("Here you will find your history.")
    //
    //        tester.tapViewWithAccessibilityLabel("cliqzBack")
    //        tester.setText("cliqz.com", intoViewWithAccessibilityLabel: "Address and Search")
    //        tester.waitForSoftwareKeyboard()
    //        tester.tapViewWithAccessibilityLabel("Go")
    //
    //        tester.tapViewWithAccessibilityLabel("OK")
    //        tester.tapViewWithAccessibilityLabel("Address and Search")
    //        tester.waitForSoftwareKeyboard()
    //        tester.tapViewWithAccessibilityLabel("Go")
    //        tester.waitForTimeInterval(5)
    //        tester.tapViewWithAccessibilityLabel("Show Tabs")
    //        tester.tapViewWithAccessibilityLabel("History")
    //        system.waitForTimeInterval(3)
    ////        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("cf answer"), "No element with cf answer")
    ////        tester.hasWebViewElementWithAccessibilityLabel("Blah blalakjks")
    //    }
    //    func testFavoritesTab(){
    //    
    //    }
}
