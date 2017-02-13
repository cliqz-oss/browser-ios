//
//  CliqzTestsExtension.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

extension XCTestCase {

    func openWebPage(url:String){
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            tester.tapViewWithAccessibilityIdentifier("url")
        }
        tester.waitForTimeInterval(1)
        tester.setText(url, intoViewWithAccessibilityLabel: "Address and Search")
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

    func goToLinkInWebPage(){
        tester.waitForViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapViewWithAccessibilityLabel("delete")
        tester.tapViewWithAccessibilityLabel("Address and Search")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.tapViewWithAccessibilityLabel("Go")
        tester.waitForTimeInterval(1)
    }

    func showToolBar(){
        if tester.viewExistsWithLabel("urlExpand"){
            tester.tapViewWithAccessibilityLabel("urlExpand")
            tester.waitForAbsenceOfSoftwareKeyboard()
            tester.waitForViewWithAccessibilityLabel("Show Tabs")
        }
    }
    
    func resetApp(accessibilityLabels: [String]){
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel(accessibilityLabel)
        for accessibilityLabel in accessibilityLabels {
            tester.swipeViewWithAccessibilityLabel(accessibilityLabel, inDirection: KIFSwipeDirection.Left)
            tester.waitForTimeInterval(1)
        }
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            tester.tapViewWithAccessibilityIdentifier("url")
        }
    }
    
}
