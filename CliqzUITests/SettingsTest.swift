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

    func testSettingsAndDoneButtons() {
        tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(tester.viewExistsWithLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")), "Done button should exist on this view")
        tester.tapViewWithAccessibilityLabel(NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"))
        tester.tapViewWithAccessibilityLabel("cliqzBack")
    }
    
//    func testSearchEngineChange() {
//        tester.waitForFirstResponderWithAccessibilityLabel("Address and Search")
//        tester.waitForTimeInterval(3)
//        tester.setText("abc", intoViewWithAccessibilityLabel: "Address and Search")
//        tester.waitForSoftwareKeyboard()
//        tester.tapViewWithAccessibilityLabel("Go")
//        if tester.viewExistsWithLabel("OK"){
//            tester.tapViewWithAccessibilityLabel("OK")
//            tester.tapViewWithAccessibilityLabel("Address and Search")
//            tester.waitForSoftwareKeyboard()
//            tester.tapViewWithAccessibilityLabel("Go")
//        }
//        tester.waitForTimeInterval(5)
//        let y = tester.waitForTappableViewWithAccessibilityIdentifier("url") as? UITextField
//        let z = y?.text
//        
//        tester.waitForViewWithAccessibilityLabel("Show Tabs")
//        tester.tapViewWithAccessibilityLabel("Show Tabs")
//        XCTAssertTrue(tester.viewExistsWithLabel(z!))
//        XCTAssertTrue(tester.viewExistsWithLabel("Settings"))
//        tester.tapViewWithAccessibilityLabel("Settings")
//        
//    }

    func testSearchEngineChangeCheckmark(){
        //        Test the functionality
        showToolBar()
        tester.waitForViewWithAccessibilityLabel("Show Tabs")
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertTrue(tester.viewExistsWithLabel("Settings"), "Settings button should exist on this view")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search, Google")
        XCTAssertTrue((tester.waitForViewWithAccessibilityLabel("Google", traits: UIAccessibilityTraitSelected)) != nil, "Default Search Engine is not google")
        tester.tapViewWithAccessibilityLabel("Twitter")
        XCTAssertTrue((tester.waitForViewWithAccessibilityLabel("Twitter", traits: UIAccessibilityTraitSelected)) != nil, "Search Engine Twitter was not selected after tapping it")
        tester.tapViewWithAccessibilityLabel("Settings")
        XCTAssertTrue(tester.viewExistsWithLabel("Search, Twitter"), "Search Engine Label did not change to Twitter")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("cliqzBack")
        tester.waitForTimeInterval(1)
    }

    func testBlockPopUpWindowsWhenEnabledByDefault() {
        //        Tests if button functions
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
        tester.tapViewWithAccessibilityIdentifier("url")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
        }
        tester.waitForTimeInterval(2)
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
        tester.tapViewWithAccessibilityIdentifier("url")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
        }
        tester.waitForTimeInterval(2)
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
//        tester.tapViewWithAccessibilityLabel("urlExpand")
        XCTAssertTrue(tabsCounter.accessibilityValue == "1", "More than one tab is opened, Only one tab should be opened")
        tester.tapViewWithAccessibilityIdentifier("url")
        tester.setText("https://cdn.cliqz.com/mobile/browser/tests/popup_test.html", intoViewWithAccessibilityLabel: "Address and Search")
        tester.waitForSoftwareKeyboard()
        tester.tapViewWithAccessibilityLabel("Go")
        if tester.viewExistsWithLabel("OK"){
            tester.tapViewWithAccessibilityLabel("OK")
            tester.tapViewWithAccessibilityLabel("Address and Search")
            tester.waitForSoftwareKeyboard()
            tester.tapViewWithAccessibilityLabel("Go")
        }
        tester.waitForTimeInterval(2)
//        showToolBar()
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

