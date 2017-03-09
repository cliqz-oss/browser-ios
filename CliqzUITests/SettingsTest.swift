//
//  SettingsTest.swift
//  Client
//
//  Created by Kiiza Joseph Bazaare on 12/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import KIF

class SettingsTests: KIFTestCase {
    
    override func tearDown() {
        if tester.viewExistsWithLabel("Settings"){
            tester.tapViewWithAccessibilityLabel("Settings")
        }
        if tester.viewExistsWithLabel("Done"){
            tester.tapViewWithAccessibilityLabel("Done")
        }
        if tester.viewExistsWithLabel("cliqzBack"){
            tester.tapViewWithAccessibilityLabel("closeTab")
            tester.tapViewWithAccessibilityLabel("cliqzBack")
        }
        super.tearDown()
    }

    func testSettingsAndDoneButtons() {
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(tester.viewExistsWithLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")), "Done button should exist on this view")
        tester.tapViewWithAccessibilityLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"))
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
    func testSearchEngineChange() {
        showToolBar()
        tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search, Google")
        checkSearchEngineChange("Amazon.com",query:"heli",url:"https://www.amazon.com/gp/aw/s?k=heli")
        checkSearchEngineChange("Bing",query: "heli", url: "https://www.bing.com/search?q=heli")
        checkSearchEngineChange("DuckDuckGo", query: "heli", url: "https://duckduckgo.com/?q=heli")
        checkSearchEngineChange("Ecosia", query: "fir", url: "https://www.ecosia.org/search?q=fir")
        checkSearchEngineChange("Google", query: "dor", url: "https://www.google.com/search?q=dor")
        checkSearchEngineChange("Qwant", query: "dor", url: "https://www.qwant.com/?q=dor")
        checkSearchEngineChange("Twitter", query: "dor", url: "https://mobile.twitter.com/search/?q=dor")
        checkSearchEngineChange("Wikipedia", query: "germany", url: "https://en.m.wikipedia.org/wiki/Germany")
        checkSearchEngineChange("Wikipedia", query: "bkjdydgd", url: "https://en.m.wikipedia.org/wiki/Special:Search?search=bkjdydgd")
        checkSearchEngineChange("Yahoo", query: "blah", url: "https://search.yahoo.com/yhs/search?")
        tester.tapViewWithAccessibilityLabel("Google")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        let searchUrl = tester.waitForViewWithAccessibilityIdentifier("url")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        let Label = searchUrl.accessibilityValue!
        tester.swipeViewWithAccessibilityLabel("\(Label)", inDirection: KIFSwipeDirection.Left)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
        
    }

    func testSearchEngineChangeCheckmark(){
        showToolBar()
        tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search, Google")
        XCTAssertTrue((tester.waitForViewWithAccessibilityLabel("Google", traits: UIAccessibilityTraitSelected)) != nil, "Default Search Engine is not google")
        let searchEngines = ["Amazon.com","Bing","DuckDuckGo","Ecosia","Google","Qwant","Twitter","Wikipedia","Yahoo"]
        for searchEngine in searchEngines {
            changeAndCheckSearchEngineLabel(searchEngine)
        }
        tester.tapViewWithAccessibilityLabel("Google")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }

    func testBlockPopUpWindowsWhenEnabledByDefault() {
        //        Tests if block PopupButton button functions
        showToolBar()
        let tabsCounter = tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        let popUpSlider = tester.waitForViewWithAccessibilityLabel("Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(popUpSlider.accessibilityValue == "1", "Block Pop-up Windows is not turned on, It should be on!")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", inDirection: KIFSwipeDirection.Left)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }

    func testBlockPopUpWindowsWhenDisabled(){
        //        Tests if the popups are blocked when pop-up blocker is activated
        showToolBar()
        let tabsCounter = tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        let popUpSlider = tester.waitForViewWithAccessibilityLabel("Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        tester.swipeViewWithAccessibilityLabel("Block Pop-up Windows", value: "1", traits:UIAccessibilityTraitButton, inDirection: KIFSwipeDirection.Left)
        tester.waitForAnimationsToFinish()
        XCTAssertTrue(popUpSlider.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter.accessibilityValue == "2", "Less than two or more than two tabs are open, Two tabs should be opened")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", inDirection: KIFSwipeDirection.Left)
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", inDirection: KIFSwipeDirection.Left)
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.swipeViewWithAccessibilityLabel("Block Pop-up Windows", value: "0", traits:UIAccessibilityTraitButton, inDirection: KIFSwipeDirection.Right)
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }

    func testBlockPopUpWindowsWhenEnabled(){
        showToolBar()
        let tabsCounter = tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        var popUpSlider = tester.waitForViewWithAccessibilityLabel("Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        tester.swipeViewWithAccessibilityLabel("Block Pop-up Windows", value: "1", traits:UIAccessibilityTraitButton, inDirection: KIFSwipeDirection.Left)
        tester.waitForAnimationsToFinish()
        XCTAssertTrue(popUpSlider.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(popUpSlider.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.swipeViewWithAccessibilityLabel("Block Pop-up Windows", value: "0", traits:UIAccessibilityTraitButton, inDirection: KIFSwipeDirection.Right)
        tester.waitForAnimationsToFinish()
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        popUpSlider = tester.waitForViewWithAccessibilityLabel("Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(popUpSlider.accessibilityValue == "1", "Block Pop-up Windows is not turned on, It should be on!")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", inDirection: KIFSwipeDirection.Left)
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }

}

