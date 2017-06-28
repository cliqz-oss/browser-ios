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

    func testSettingsAndDoneButtons() {
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapView(withAccessibilityLabel: "Settings")
        XCTAssertTrue(tester.viewExistsWithLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")), "Done button should exist on this view")
        tester.tapView(withAccessibilityLabel: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"))
        tester.tapView(withAccessibilityLabel: "cliqzBack")
    }
    
    func testSearchEngineChange() {
        showToolBar()
        tester.waitForView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "\(getComplementarySearchIdentifier()), Google")
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
        tester.tapView(withAccessibilityLabel: "Google")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        let searchUrl = tester.waitForView(withAccessibilityIdentifier: "url")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        let Label = searchUrl?.accessibilityValue!
        tester.swipeView(withAccessibilityLabel: "\(Label)", in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
    }

    func testSearchEngineChangeCheckmark(){
        showToolBar()
        tester.waitForView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "\(getComplementarySearchIdentifier()), Google")
        XCTAssertTrue((tester.waitForView(withAccessibilityLabel: "Google", traits: UIAccessibilityTraitSelected)) != nil, "Default Search Engine is not google")
        let searchEngines = ["Amazon.com","Bing","DuckDuckGo","Ecosia","Google","Qwant","Twitter","Wikipedia","Yahoo"]
        for searchEngine in searchEngines {
            changeAndCheckSearchEngineLabel(accessibilityLabel: searchEngine)
        }
        tester.tapView(withAccessibilityLabel: "Google")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
    }

    func testBlockPopUpWindowsWhenEnabledByDefault() {
        //        Tests if block PopupButton button functions
        showToolBar()
        let tabsCounter = tester.waitForView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapView(withAccessibilityLabel: "Settings")
        let popUpSlider = tester.waitForView(withAccessibilityLabel: "Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(popUpSlider?.accessibilityValue == "1", "Block Pop-up Windows is not turned on, It should be on!")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.swipeView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
            }

    func testBlockPopUpWindowsWhenDisabled(){
        //        Tests if the popups are blocked when pop-up blocker is activated
        showToolBar()
        let tabsCounter = tester.waitForView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapView(withAccessibilityLabel: "Settings")
        let popUpSlider = tester.waitForView(withAccessibilityLabel: "Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        tester.swipeView(withAccessibilityLabel: "Block Pop-up Windows", value: "1", traits:UIAccessibilityTraitButton, in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
        XCTAssertTrue(popUpSlider?.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "2", "Less than two or more than two tabs are open, Two tabs should be opened")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.swipeView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
        tester.swipeView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/testpage.html", in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.swipeView(withAccessibilityLabel: "Block Pop-up Windows", value: "0", traits:UIAccessibilityTraitButton, in: KIFSwipeDirection.right)
        tester.waitForAnimationsToFinish()
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        tester.wait(forTimeInterval: 1)
    }

    func testBlockPopUpWindowsWhenEnabled(){
        showToolBar()
        let tabsCounter = tester.waitForView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        var popUpSlider = tester.waitForView(withAccessibilityLabel: "Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        tester.swipeView(withAccessibilityLabel: "Block Pop-up Windows", value: "1", traits:UIAccessibilityTraitButton, in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
        XCTAssertTrue(popUpSlider?.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "Settings")
        XCTAssertTrue(popUpSlider?.accessibilityValue == "0", "Block Pop-up Windows is turned on, it should be off!")
        tester.swipeView(withAccessibilityLabel: "Block Pop-up Windows", value: "0", traits:UIAccessibilityTraitButton, in: KIFSwipeDirection.right)
        tester.waitForAnimationsToFinish()
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        openWebPage(url: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html")
        XCTAssertTrue(tabsCounter?.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        popUpSlider = tester.waitForView(withAccessibilityLabel: "Block Pop-up Windows", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(popUpSlider?.accessibilityValue == "1", "Block Pop-up Windows is  turned off, It should be on!")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.swipeView(withAccessibilityLabel: "https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", in: KIFSwipeDirection.left)
        tester.waitForAnimationsToFinish()
    }
    
    func testViewSearchResultsForSettings(){
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Search Results for, Germany")
        XCTAssertTrue(tester.waitForView(withAccessibilityLabel: "Germany", traits: UIAccessibilityTraitSelected) != nil ,"Search results for Germany is not selected.")
        tester.tapView(withAccessibilityLabel: "France")
        XCTAssertTrue(tester.waitForView(withAccessibilityLabel: "France", traits: UIAccessibilityTraitSelected) != nil ,"Search results for  France is not selected.")
        tester.tapView(withAccessibilityLabel: "United States")
        XCTAssertTrue(tester.waitForView(withAccessibilityLabel: "United States", traits: UIAccessibilityTraitSelected) != nil ,"Search results for United States is not selected.")
        tester.tapView(withAccessibilityLabel: "Germany")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
    }
    
    func testViewHumanWebSettings(){
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Human Web, On")
        let humanWebSlider = tester.waitForView(withAccessibilityLabel: "Human Web", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(humanWebSlider?.accessibilityValue == "1", "Human web is not activated by Default, it should be activated. \(humanWebSlider?.accessibilityValue)")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
    }
    
    func testViewAdBlockSettings(){
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Ad-Blocking (Beta), Off")
        let adBlockSlider = tester.waitForView(withAccessibilityLabel: "Ad-Blocking (Beta)")
        XCTAssertTrue(adBlockSlider?.accessibilityValue == "0", "Ad-Blocking (Beta) is activated by Default, it shouldn't be activated.\(adBlockSlider?.accessibilityValue)")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
    }
    
    func testViewClearPrivateDataSettings(){
        showToolBar()
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Clear Private Data")
        let browsingHistorySlider = tester.waitForView(withAccessibilityLabel: "Browsing History", traits: UIAccessibilityTraitButton)
        let favoritesSlider = tester.waitForView(withAccessibilityLabel: "Favorites", traits: UIAccessibilityTraitButton)
        let cacheSlider = tester.waitForView(withAccessibilityLabel: "Cache", traits: UIAccessibilityTraitButton)
        let cookiesSlider = tester.waitForView(withAccessibilityLabel: "Cookies", traits: UIAccessibilityTraitButton)
        let offlineWebsiteDataSlider = tester.waitForView(withAccessibilityLabel: "Offline Website Data", traits: UIAccessibilityTraitButton)
        XCTAssertTrue(browsingHistorySlider?.accessibilityValue == "1", "Browsing History is  not activated by Default, it should be activated \(browsingHistorySlider?.accessibilityValue).")
        XCTAssertTrue(favoritesSlider?.accessibilityValue == "0", "Favorites is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(cacheSlider?.accessibilityValue == "0", "Cache is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(cookiesSlider?.accessibilityValue == "0", "Cookies is activated by Default, it shouldn't be activated.")
        XCTAssertTrue(offlineWebsiteDataSlider?.accessibilityValue == "0", "Offline Website Data is activated by Default, it shouldn't be activated.")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "Done")
        tester.tapView(withAccessibilityLabel: "cliqzBack")
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
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.tapView(withAccessibilityLabel: "Settings")
        tester.tapView(withAccessibilityLabel: "FAQ & Support")
        tester.waitForAnimationsToFinish()
        tester.waitForView(withAccessibilityLabel: "https://cliqz.com/en/support")
        XCTAssertTrue(tester.viewExistsWithLabel("https://cliqz.com/en/support"), "Expected url https://cliqz.com/en/support, found something else")
        tester.tapView(withAccessibilityLabel: "Show Tabs")
        tester.swipeView(withAccessibilityLabel: "https://cliqz.com/en/support", in: KIFSwipeDirection.left)
    }
    
}


