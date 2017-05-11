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

		tester.waitForViewWithAccessibilityLabel(NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns."))
		tester.enterTextIntoCurrentFirstResponder("Cliqz")
        tester.waitForTimeInterval(1)
        let searchBar = tester.waitForViewWithAccessibilityLabel("Address and Search")
        XCTAssertTrue(searchBar.accessibilityValue!.startsWith("Cliqz"), "Search Bar is not Focused on Opening the application, It Should be!")
        tester.tapViewWithAccessibilityLabel("CliqzClear")
	}
    
    func testQuerySuggestion(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        let searchQuerySuggestion = tester.waitForViewWithAccessibilityLabel("Search Query Suggestions")
        XCTAssertTrue(searchQuerySuggestion.accessibilityValue == "1", "Search Query suggestion is turned off, it should be turned on by default")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.enterTextIntoCurrentFirstResponder("Cliqz")
        XCTAssertTrue(tester.viewExistsWithLabel("cliqz browser"), "Query suggestion is turned on but is not displayed")
        tester.tapViewWithAccessibilityLabel("CliqzClear")
    }
    
    func testQuerySuggestionDisabled(){
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        let searchQuerySuggestion = tester.waitForViewWithAccessibilityLabel("Search Query Suggestions")
        XCTAssertTrue(searchQuerySuggestion.accessibilityValue == "1", "Search Query suggestion is turned off, it should be turned on by default")
        tester.swipeViewWithAccessibilityLabel("Search Query Suggestions", inDirection: KIFSwipeDirection.Left)
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.enterTextIntoCurrentFirstResponder("Cliqz")
        XCTAssertFalse(tester.viewExistsWithLabel("cliqz browser"), "Query suggestion is turned off but a query suggestion is  displayed")
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(searchQuerySuggestion.accessibilityValue == "0","Search Query suggestion is turned on, it should be turned off" )
        tester.swipeViewWithAccessibilityLabel("Search Query Suggestions", inDirection: KIFSwipeDirection.Right)
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
//    func testAutoCompletion(){
//        tester.waitForAnimationsToFinish()
//        tester.waitForTimeInterval(3)
//        tester.tapViewWithAccessibilityLabel("c")
//        tester.tapViewWithAccessibilityLabel("l")
//        tester.tapViewWithAccessibilityLabel("i")
//        tester.tapViewWithAccessibilityLabel("q")
//        tester.tapViewWithAccessibilityLabel("z")
//        tester.enterTextIntoCurrentFirstResponder("cliqz")
//        tester.waitForTimeInterval(1)
//        let searchBar = tester.waitForViewWithAccessibilityLabel("Address and Search")
//        XCTAssertTrue(searchBar.accessibilityValue!.contains("cliqz.com/"), "Auto completion is not working, returns \(searchBar.accessibilityValue!) instead of cliqz.com")
//        tester.tapViewWithAccessibilityLabel("CliqzClear")
//    }

    
    //    func testHistoryButton() {
    //	    Use recording to get started writing UI tests.
    //		tester.waitForViewWithAccessibilityLabel("HistoryButton")
    //		tester.tapViewWithAccessibilityLabel("HistoryButton")
    //		XCTAssertTrue(tester.viewExistsWithLabel("CloseHistoryButton"))
    //		tester.tapViewWithAccessibilityLabel("CloseHistoryButton")
    //	}

    //    func testHistoryTab(){
    //        tester.waitForSoftwareKeyboard()
    //        tester.waitForViewWithAccessibilityLabel("Show Tabs")
    //        tester.tapViewWithAccessibilityLabel("Show Tabs")
    //        tester.waitForViewWithAccessibilityLabel("History")
    //        tester.tapViewWithAccessibilityLabel("History")
    //        tester.waitForWebViewElementWithAccessibilityLabel("nohistoryyet")
    //        system.waitForTimeInterval(4)
    //        system.waitForNotificationName("ExtensionIsReady", object: nil)
    //       XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("Her find"), "No element with cf answer")
    //        tester.hasWebViewElementWithAccessibilityLabel("Here you will find your history.")
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
    //        XCTAssertTrue(tester.hasWebViewElementWithAccessibilityLabel("cf answer"), "No element with cf answer")
    //        tester.hasWebViewElementWithAccessibilityLabel("Blah blalakjks")
    //    }
    //    func testFavoritesTab(){
    //    
    //    }
}
