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
            tester.tapView(withAccessibilityLabel: "Back to safe site")
        }
        if tester.viewExistsWithLabel("Show Tabs"){
            tester.tapView(withAccessibilityLabel: "Show Tabs")
        }
        if tester.viewExistsWithLabel("Settings"){
            tester.tapView(withAccessibilityLabel: "Settings")
        }
        if tester.viewExistsWithLabel("Done"){
            tester.tapView(withAccessibilityLabel: "Done")
        }
        if tester.viewExistsWithLabel("cliqzBack"){
            tester.tapView(withAccessibilityLabel: "closeTab")
        }
        super.tearDown()
    }
    func testAntiPhishing() {
        openWebPage(url: "https://varvy.com/pagespeed/wicked-fast.html")
        XCTAssertFalse(tester.viewExistsWithLabel("Warning: deceptive website!"),
                       "AntiPhishing website is shown for https://varvy.com/pagespeed/wicked-fast.html when it shouldn't")
        openWebPage(url: "http://marketing-customer.info/webapps/ab983f6f33/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"),
                      "AntiPhishing Warning is not shown for http://marketing-customer.info/webapps/ab983f6f33")
        tester.tapView(withAccessibilityLabel: "Back to safe site")
        openWebPage(url: "http://mouyondzi.com/dropbox-file/dropbox-secured/document/")
        XCTAssertTrue(tester.viewExistsWithLabel("Warning: deceptive website!"),
                      "AntiPhishing Warning is not shown for http://mouyondzi.com/dropbox-file/dropbox-secured/document/")
        tester.tapView(withAccessibilityLabel: "Back to safe site")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "closeTab")
        tester.wait(forTimeInterval: 2)
    }
    
}
