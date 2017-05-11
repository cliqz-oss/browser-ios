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
        tester.tapViewWithAccessibilityLabel("\(getComplementarySearchIdentifier()), Google")
        checkSearchEngineChange("Amazon.com",query:"heli",url:"https://www.amazon.com/gp/aw/s?k=heli")
        checkSearchEngineChange("Bing",query: "heli", url: "https://www.bing.com/search?q=heli")
        checkSearchEngineChange("DuckDuckGo", query: "heli", url: "https://duckduckgo.com/?q=heli")
        checkSearchEngineChange("Ecosia", query: "fir", url: "https://www.ecosia.org/search?q=fir")
        checkSearchEngineChange("Google", query: "dor", url: "https://www.google.de/search?q=dor")
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
        tester.waitForAnimationsToFinish()
    }

    func testSearchEngineChangeCheckmark(){
        showToolBar()
        tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("\(getComplementarySearchIdentifier()), Google")
        XCTAssertTrue((tester.waitForViewWithAccessibilityLabel("Google", traits: UIAccessibilityTraitSelected)) != nil, "Default Search Engine is not google")
        let searchEngines = ["Amazon.com","Bing","DuckDuckGo","Ecosia","Google","Qwant","Twitter","Wikipedia","Yahoo"]
        for searchEngine in searchEngines {
            changeAndCheckSearchEngineLabel(searchEngine)
        }
        tester.tapViewWithAccessibilityLabel("Google")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
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
        tester.waitForAnimationsToFinish()
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
        tester.waitForAnimationsToFinish()
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/testpage.html", inDirection: KIFSwipeDirection.Left)
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.swipeViewWithAccessibilityLabel("Block Pop-up Windows", value: "0", traits:UIAccessibilityTraitButton, inDirection: KIFSwipeDirection.Right)
        tester.waitForAnimationsToFinish()
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
        XCTAssertTrue(popUpSlider.accessibilityValue == "1", "Block Pop-up Windows is  turned off, It should be on!")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.swipeViewWithAccessibilityLabel("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", inDirection: KIFSwipeDirection.Left)
        tester.waitForAnimationsToFinish()
    }
    
    func testViewSearchResultsForSettings(){
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search Results for, Germany")
        XCTAssertTrue(tester.waitForViewWithAccessibilityLabel("Germany", traits: UIAccessibilityTraitSelected) != nil ,"Search results for Germany is not selected.")
        tester.tapViewWithAccessibilityLabel("France")
        XCTAssertTrue(tester.waitForViewWithAccessibilityLabel("France", traits: UIAccessibilityTraitSelected) != nil ,"Search results for  France is not selected.")
        tester.tapViewWithAccessibilityLabel("United States")
        XCTAssertTrue(tester.waitForViewWithAccessibilityLabel("United States", traits: UIAccessibilityTraitSelected) != nil ,"Search results for United States is not selected.")
        tester.tapViewWithAccessibilityLabel("Germany")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
    func testViewHumanWebSettings(){
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Human Web, On")
        let humanWebSlider = tester.waitForViewWithAccessibilityLabel("Human Web", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(humanWebSlider.accessibilityValue == "1", "Human web is not activated by Default, it should be activated.")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
    func testViewAdBlockSettings(){
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Ad-Blocking (Beta), Off")
        let adBlockSlider = tester.waitForViewWithAccessibilityLabel("Ad-Blocking (Beta)", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(adBlockSlider.accessibilityValue == "0", "Ad-Blocking (Beta) is activated by Default, it shouldn't be activated.")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
    func testViewClearPrivateDataSettings(){
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Clear Private Data")
        let browsingHistorySlider = tester.waitForViewWithAccessibilityLabel("Browsing History", traits: UIAccessibilityTraitButton)
        let favoritesSlider = tester.waitForViewWithAccessibilityLabel("Favorites", traits: UIAccessibilityTraitButton)
        let cacheSlider = tester.waitForViewWithAccessibilityLabel("Cache", traits: UIAccessibilityTraitButton)
        let cookiesSlider = tester.waitForViewWithAccessibilityLabel("Cookies", traits: UIAccessibilityTraitButton)
        let offlineWebsiteDataSlider = tester.waitForViewWithAccessibilityLabel("Offline Website Data", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(browsingHistorySlider.accessibilityValue == "1", "Browsing History is  not activated by Default, it should be activated \(browsingHistorySlider.accessibilityValue).")
        XCTAssertTrue(favoritesSlider.accessibilityValue == "0", "Favorites is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(cacheSlider.accessibilityValue == "0", "Cache is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(cookiesSlider.accessibilityValue == "0", "Cookies is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(offlineWebsiteDataSlider.accessibilityValue == "0", "Offline Website Data is activated by Default, it shouldn't be activated.")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
//    func testRestoreMostVisitedWebsites(){
//        showToolBar()
//        tester.tapViewWithAccessibilityLabel("Show Tabs")
//        tester.tapViewWithAccessibilityLabel("Settings")
//        tester.tapViewWithAccessibilityLabel("Restore Most Visited Websites")
//        XCTAssertTrue(tester.viewExistsWithLabel("Restore Most Visited Websites"), "Restore Most Visited Websites pop up is not displayed")
//        XCTAssertTrue(tester.viewExistsWithLabel("Cancel"), "Restore Most Visited Websites pop up is not displayed")
//        tester.tapViewWithAccessibilityLabel("Cancel")
//    }
    
    func testviewFAQAndSupportSettings(){
        showToolBar()
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("FAQ & Support")
        tester.waitForAnimationsToFinish()
        tester.waitForViewWithAccessibilityLabel("https://cliqz.com/en/support")
        XCTAssertTrue(tester.viewExistsWithLabel("https://cliqz.com/en/support"), "Expected url https://cliqz.com/en/support, found something else")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.swipeViewWithAccessibilityLabel("https://cliqz.com/en/support", inDirection: KIFSwipeDirection.Left)
    }
    
}


