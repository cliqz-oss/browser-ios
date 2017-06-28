//
//  CliqzTestsExtension.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

extension XCTestCase {
    func getComplementarySearchIdentifier() -> String {
        return "Complementary Search"
    }
    
    func openWebPage(url:String){
        // TO DO cater for navigating to a web page when not at the inital state
//        tester.acknowledgeSystemAlert()
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            if tester.viewExistsWithLabel("Address and Search"){
                tester.tapView(withAccessibilityLabel: "Address and Search")
            }
            else{
                tester.tapView(withAccessibilityIdentifier: "url")
            }
        }
        tester.tapView(withAccessibilityLabel: "delete")
        tester.setText(url, intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapView(withAccessibilityLabel: "Go")
//        let checkOnboarding = try tester.tryFindingTappableViewWithAccessibilityLabel("OK")
        if  tester.viewExistsWithLabel("OK") {
            tester.tapView(withAccessibilityLabel: "OK")
            tester.tapView(withAccessibilityLabel: "Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapView(withAccessibilityLabel: "Go")
            tester.wait(forTimeInterval: 1)
        }
        tester.wait(forTimeInterval: 1)
    }

    func goToLinkInWebPage(){
        tester.waitForView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/forward_test.html")
        tester.tapView(withAccessibilityLabel: "delete")
        tester.tapView(withAccessibilityLabel: "Address and Search")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.tapView(withAccessibilityLabel: "Go")
        tester.wait(forTimeInterval: 1)
    }

    func showToolBar(){
        if tester.viewExistsWithLabel("urlExpand"){
            tester.tapView(withAccessibilityLabel: "urlExpand")
            tester.waitForAbsenceOfSoftwareKeyboard()
            tester.waitForView(withAccessibilityLabel: "Show Tabs")
        }
    }
    
    func resetApp(_ accessibilityLabels: [String]){
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.waitForView(withAccessibilityLabel: accessibilityLabel)
        for accessibilityLabel in accessibilityLabels {
            tester.waitForView(withAccessibilityLabel: accessibilityLabel)
            tester.tapView(withAccessibilityLabel: "closeTab")
            tester.wait(forTimeInterval: 1)
        }
        if tester.viewExistsWithLabel("Go"){
        }
        else{
            if tester.viewExistsWithLabel("Address and Search"){
                tester.tapView(withAccessibilityLabel: "")
                tester.tapView(withAccessibilityLabel: "Search")
            }
            else{
                tester.tapView(withAccessibilityIdentifier: "url")
            }
        }
    }
    
    func changeAndCheckSearchEngineLabel(accessibilityLabel:String){
        tester.tapView(withAccessibilityLabel: accessibilityLabel)
        XCTAssertTrue((tester.waitForView(withAccessibilityLabel: accessibilityLabel, traits: UIAccessibilityTraitSelected)) != nil, "Search Engine \(accessibilityLabel) was not selected after tapping it")
        tester.tapView(withAccessibilityLabel: "Settings")
        XCTAssertTrue(tester.viewExistsWithLabel("\(getComplementarySearchIdentifier()), \(accessibilityLabel)"), "Search Engine Label did not change to \(accessibilityLabel)")
        tester.tapView(withAccessibilityLabel: "\(getComplementarySearchIdentifier()), \(accessibilityLabel)")
    }
    
    func checkSearchEngineChange(_ accessibilityLabel:String, query:String, url:String){
        tester.tapView(withAccessibilityLabel: "\(accessibilityLabel)")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        if tester.viewExistsWithLabel("Address and Search"){
        tester.tapView(withAccessibilityLabel: "Address and Search")
        }
        else{
        tester.tapView(withAccessibilityIdentifier: "url")
        }
        let urlBar = tester.waitForView(withAccessibilityLabel: "Address and Search")
        if urlBar?.accessibilityValue == query{
            tester.tapView(withAccessibilityLabel: "Go")
            if tester.viewExistsWithLabel("OK"){
                tester.tapView(withAccessibilityLabel: "OK")
                if tester.viewExistsWithLabel("Address and Search"){
                    tester.tapView(withAccessibilityLabel: "Address and Search")
                }
                else{
                    tester.tapView(withAccessibilityIdentifier: "url")
                }
                tester.waitForSoftwareKeyboard()
                tester.tapView(withAccessibilityLabel: "Go")
            }
            tester.wait(forTimeInterval: 3)
        }
        else{
            tester.tapView(withAccessibilityLabel: "delete")
            tester.setText(query, intoViewWithAccessibilityLabel: "Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapView(withAccessibilityLabel: "Go")
            if tester.viewExistsWithLabel("OK"){
                tester.tapView(withAccessibilityLabel: "OK")
                if tester.viewExistsWithLabel("Address and Search"){
                    tester.tapView(withAccessibilityLabel: "Address and Search")
                }
                else{
                    tester.tapView(withAccessibilityIdentifier: "url")
                }
                tester.waitForSoftwareKeyboard()
                tester.tapView(withAccessibilityLabel: "Go")
            }
            tester.wait(forTimeInterval: 3)
        }
//        if tester.viewExistsWithLabel("")
        let searchUrl = tester.waitForView(withAccessibilityIdentifier: "url")
        XCTAssertTrue((searchUrl!.accessibilityValue!.startsWith(url)), "Search Engine url is  \(searchUrl!.accessibilityValue!) instead of \(url)")
		
		XCTAssertTrue((searchUrl?.accessibilityValue!.localizedCaseInsensitiveContains(query))!)
        if tester.viewExistsWithLabel("OK"){
            tester.tapView(withAccessibilityLabel: "OK")
        }
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "\(getComplementarySearchIdentifier()), \(accessibilityLabel)")
    }
    
}
