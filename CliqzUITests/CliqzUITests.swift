//
//  CliqzUITests.swift
//  CliqzUITests
//
//  Created by Sahakyan on 2/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest

class CliqzUITests: KIFTestCase {

    func testHistoryButton() {
		// Use recording to get started writing UI tests.
		tester.waitForViewWithAccessibilityLabel("HistoryButton")
		tester.tapViewWithAccessibilityLabel("HistoryButton")
		XCTAssertTrue(tester.viewExistsWithLabel("CloseHistoryButton"))
		tester.tapViewWithAccessibilityLabel("CloseHistoryButton")
	}

	func testSettingsButton() {
		tester.waitForViewWithAccessibilityLabel("HistoryButton")
		tester.tapViewWithAccessibilityLabel("HistoryButton")
//		XCTAssertTrue(tester.viewExistsWithLabel("OpenSettingsButton"))
//		tester.tapViewWithAccessibilityLabel("OpenSettingsButton")
//		XCTAssertTrue(tester.viewExistsWithLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")))
//		tester.tapViewWithAccessibilityLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"))
	}
	
	func testSearch() {
		tester.waitForViewWithAccessibilityLabel(NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns."))
		tester.enterTextIntoCurrentFirstResponder("Hello")
	}
	
}
