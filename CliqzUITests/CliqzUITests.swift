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
		XCTAssertTrue(tester.viewExistsWithLabel("OpenSettingsButton"))
		tester.tapViewWithAccessibilityLabel("OpenSettingsButton")
		XCTAssertTrue(tester.viewExistsWithLabel("Done"))
		tester.tapViewWithAccessibilityLabel("Done")
	}
	
	func testSearch() {
		tester.waitForViewWithAccessibilityLabel("Address and Search")
		tester.enterTextIntoCurrentFirstResponder("Hello")
	}
}
