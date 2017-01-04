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
        
        tester.setText(url, intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
            tester.waitForTimeInterval(1)
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
    
    func changeAndCheckSearchEngineLabel(accessibilityLabel:String){
        tester.tapViewWithAccessibilityLabel(accessibilityLabel)
        XCTAssertTrue((tester.waitForViewWithAccessibilityLabel(accessibilityLabel, traits: UIAccessibilityTraitSelected)) != nil, "Search Engine Twitter was not selected after tapping it")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(tester.viewExistsWithLabel("Search, \(accessibilityLabel)"), "Search Engine Label did not change to \(accessibilityLabel)")
        tester.tapViewWithAccessibilityLabel("Search, \(accessibilityLabel)")
    }
    
    func checkSearchEngineChange(accessibilityLabel:String, query:String, url:String){
        tester.tapViewWithAccessibilityLabel("\(accessibilityLabel)")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.tapViewWithAccessibilityIdentifier("url")
        let urlBar = tester.waitForViewWithAccessibilityLabel("Address and Search")
        if urlBar.accessibilityValue == query{
            tester.tapViewWithAccessibilityLabel("Go")
            if tester.viewExistsWithLabel("OK"){
                tester.tapViewWithAccessibilityLabel("OK")
                tester.tapViewWithAccessibilityLabel("Address and Search")
                tester.waitForSoftwareKeyboard()
                tester.tapViewWithAccessibilityLabel("Go")
            }
            tester.waitForTimeInterval(1)
        }
        else{
            tester.tapViewWithAccessibilityLabel("delete")
            tester.setText(query, intoViewWithAccessibilityLabel: "Address and Search")
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
        let searchUrl = tester.waitForViewWithAccessibilityIdentifier("url")
        XCTAssertTrue(searchUrl.accessibilityValue!.startsWith(url))
        XCTAssertTrue(searchUrl.accessibilityValue!.localizedCaseInsensitiveContainsString(query))
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
        }
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search, \(accessibilityLabel)")
    }
    
}
