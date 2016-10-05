//
//  CliqzUITests.swift
//  CliqzUITests
//
//  Created by Sahakyan on 2/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest

class CliqzUITests: KIFTestCase {
	
	func testSearch() {
		tester.waitForViewWithAccessibilityLabel(NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns."))
		tester.enterTextIntoCurrentFirstResponder("Hello")
	}
	
}
