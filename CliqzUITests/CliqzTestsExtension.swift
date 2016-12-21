//
//  CliqzTestsExtension.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

extension XCTestCase {

    func openTestWebPage(){
        tester.waitForTimeInterval(2)
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
        }
        tester.waitForTimeInterval(1)
    }

    func gotToLinkInWebPage(){
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("delete")
        tester.tapViewWithAccessibilityLabel("Address and Search")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.tapViewWithAccessibilityLabel("Go")
        tester.waitForTimeInterval(1)
    }

    func showToolBarOnStartUp(){
        tester.waitForViewWithAccessibilityLabel("CliqzClear")
        tester.tapViewWithAccessibilityLabel("CliqzClear")
        tester.waitForAbsenceOfSoftwareKeyboard()
        tester.waitForViewWithAccessibilityLabel("New tab")
    }
    
}
