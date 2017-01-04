//
//  AntiPhishingTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 1/4/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import XCTest
import KIF

class AntiPhishingTest: KIFTestCase{
    
    func testAntiPhishing() {
        openWebPage("http://www.acorporateaffair.in/wp-content/uploads/2013/10/098/payuk/575e6cf71a991cedcb2d37e5275e5071/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"))
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        resetApp(["http://www.acorporateaffair.in/wp-content/uploads/2013/10/098/payuk/575e6cf71a991cedcb2d37e5275e5071/"])
        openWebPage("https://suport.customer-alerts.com/webapps/e362f/websrc")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"))
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        resetApp(["https://suport.customer-alerts.com/webapps/e362f/websrc"])
        openWebPage("http://account-reconfirm-secure.com216541261958151621261651495815.smk-diponegoro.sch.id/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"))
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        resetApp(["http://account-reconfirm-secure.com216541261958151621261651495815.smk-diponegoro.sch.id/"])
        openWebPage("http://marketing-customer.info/webapps/ab983f6f33/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"))
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        resetApp(["http://marketing-customer.info/webapps/ab983f6f33/"])
        openWebPage("http://mouyondzi.com/dropbox-file/dropbox-secured/document/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"))
        resetApp(["http://mouyondzi.com/dropbox-file/dropbox-secured/document/"])
    }
}
