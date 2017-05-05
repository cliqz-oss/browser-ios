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
    override func tearDown() {
        if tester.viewExistsWithLabel("Back to safe site"){
            tester.tapViewWithAccessibilityLabel("Back to safe site")
        }
        if tester.viewExistsWithLabel("Show Tabs"){
            tester.tapViewWithAccessibilityLabel("Show Tabs")
        }
        if tester.viewExistsWithLabel("Settings"){
            tester.tapViewWithAccessibilityLabel("Settings")
        }
        if tester.viewExistsWithLabel("Done"){
            tester.tapViewWithAccessibilityLabel("Done")
        }
        if tester.viewExistsWithLabel("cliqzBack"){
            tester.tapViewWithAccessibilityLabel("closeTab")
        }
        super.tearDown()
    }
    func testAntiPhishing() {
        openWebPage("http://link43wow.com.s3-website.eu-central-1.amazonaws.com/Stake7_DE_FB/desk/index.html")
        XCTAssertFalse(tester.viewExistsWithLabel("Warning: deceptive website!"),
                       "AntiPhishing website is shown for http://link43wow.com.s3-website.eu-central-1.amazonaws.com/Stake7_DE_FB/desk/index.html when it shouldn't")
        openWebPage("http://marketing-customer.info/webapps/ab983f6f33/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"),
                      "AntiPhishing Warning is not shown for http://marketing-customer.info/webapps/ab983f6f33")
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        openWebPage("http://mouyondzi.com/dropbox-file/dropbox-secured/document/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"),
                      "AntiPhishing Warning is not shown for http://mouyondzi.com/dropbox-file/dropbox-secured/document/")
        tester.tapViewWithAccessibilityLabel("Back to safe site")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("closeTab")
        tester.waitForTimeInterval(2)
    }
    
}
