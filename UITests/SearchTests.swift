/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

private let LabelPrompt = "Turn on search suggestions?"
private let HintSuggestionButton = "Searches for the suggestion"
private let LabelYahooSearchIcon = "Search suggestions from Yahoo"

class SearchTests: KIFTestCase {
    func testOptInPrompt() {
        var found: Bool

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("foobar")
        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion shown before prompt selection")

        // Ensure that suggestions are visible after selecting Yes.
        tester().tapViewWithAccessibilityLabel("Yes")
        found = tester().waitForViewWithAccessibilityHint(HintSuggestionButton) != nil
        XCTAssertTrue(found, "Found suggestions after choosing Yes")

        tester().tapViewWithAccessibilityLabel("Cancel")

        // Return to the search screen, and make sure our choice was remembered.
        found = tester().viewExistsWithLabel(LabelPrompt)

        XCTAssertFalse(found, "Prompt is not shown")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterText("foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)
        found = tester().waitForViewWithAccessibilityHint(HintSuggestionButton) != nil
        XCTAssertTrue(found, "Search suggestions are still enabled")
        tester().tapViewWithAccessibilityLabel("Cancel")
        resetSuggestionsPrompt()

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterText("foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)

        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion buttons are shown")

        // Ensure that no suggestions are visible after selecting No.
        tester().tapViewWithAccessibilityLabel("No")
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestions after choosing No")
    }

    func testChangingDyamicFontOnSearch() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("foobar")
        waitForPotentialDebounce(tester())
        tester().tapViewWithAccessibilityLabel("Yes")

        let size = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }

    func testTurnOffSuggestionsWhenEnteringURL() {
        var found: Bool

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("foobar")
        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion shown before prompt selection")

        // Ensure that suggestions are visible after selecting Yes.
        tester().tapViewWithAccessibilityLabel("Yes")
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertTrue(found, "Found suggestions after choosing Yes")
        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertTrue(found, "Found search provider icon")

        tester().tapViewWithAccessibilityLabel("Address and Search")
        tester().enterTextIntoCurrentFirstResponder("/")

        // Wait for debounce in case
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "Found suggestions after adding / to url")
        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertFalse(found, "Found no search provider icon")

        tester().tapViewWithAccessibilityLabel("Address and Search")
        tester().enterTextIntoCurrentFirstResponder(" ")

        // Wait for debounce in case
        tester().waitForTimeInterval(0.3)

        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertTrue(found, "Found search provider icon after making input url invalid")
    }

    func testURLBarContextMenu() {
        let webRoot = SimplePageServer.start()
        let testURL = "\(webRoot)/numberedPage.html?page=1"

        // Verify that Paste & Go goes to the URL.
        UIPasteboard.generalPasteboard().string = testURL
        tester().longPressViewWithAccessibilityIdentifier("url", duration: 1)
        tester().tapViewWithAccessibilityLabel("Paste & Go")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Verify that Paste shows the search controller with prompt.
        var promptFound = tester().viewExistsWithLabel(LabelPrompt)

        XCTAssertFalse(promptFound, "Search prompt is not shown")
        UIPasteboard.generalPasteboard().string = "http"
        tester().longPressViewWithAccessibilityIdentifier("url", duration: 1)
        tester().tapViewWithAccessibilityLabel("Paste")
        promptFound = tester().waitForViewWithAccessibilityLabel(LabelPrompt) != nil
        XCTAssertTrue(promptFound, "Search prompt is shown")

        // Verify that Paste triggers an autocompletion, with the correct highlighted portion.
        let textField = tester().waitForViewWithAccessibilityLabel(LabelAddressAndSearch) as! UITextField
        let expectedString = "\(webRoot)/"
        let endingString = expectedString.substringFromIndex(expectedString.startIndex.advancedBy("http".characters.count))
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "http", completion: endingString)

        tester().tapViewWithAccessibilityLabel("Cancel", traits: UIAccessibilityTraitButton)

        // Verify that Copy Address copies the text to the clipboard.
        XCTAssertNotEqual(UIPasteboard.generalPasteboard().string!, testURL, "URL is not in clipboard")
        tester().longPressViewWithAccessibilityIdentifier("url", duration: 1)
        tester().tapViewWithAccessibilityLabel("Copy Address")
        XCTAssertEqual(UIPasteboard.generalPasteboard().string!, testURL, "URL is in clipboard")

        // Verify that in-editing Paste shows the search controller with prompt.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromFirstResponder()
        tester().waitForAbsenceOfViewWithAccessibilityLabel(LabelPrompt)
        promptFound = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertFalse(promptFound, "Search prompt is not shown")
        tester().tapViewWithAccessibilityLabel(LabelAddressAndSearch)
        tester().tapViewWithAccessibilityLabel("Paste")
        promptFound = tester().waitForViewWithAccessibilityLabel(LabelPrompt) != nil
        XCTAssertTrue(promptFound, "Search prompt is shown")
    }

    var currentSearchEngine = "Yahoo"

    func searchForTerms(terms: String, withSearchEngine engine: String) {
        SearchUtils.navigateToSearchSettings(tester(), engine: currentSearchEngine)
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: engine)
        currentSearchEngine = engine
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
        tester().tapViewWithAccessibilityLabel(cell.accessibilityLabel)

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(terms)\n")
        tester().waitForTimeInterval(3.0)

        tester().tapViewWithAccessibilityIdentifier("url")
        let textField = tester().waitForViewWithAccessibilityLabel(LabelAddressAndSearch) as! UITextField
        XCTAssertEqual(terms, textField.text)
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testSearchTermExtractionDisplaysInURLBar() {
        let searchTerms = "foo bar"
        searchForTerms(searchTerms, withSearchEngine: "Amazon.com")
        searchForTerms(searchTerms, withSearchEngine: "Bing")
        searchForTerms(searchTerms, withSearchEngine: "DuckDuckGo")
        searchForTerms(searchTerms, withSearchEngine: "Google")
        searchForTerms(searchTerms, withSearchEngine: "Twitter")
        searchForTerms(searchTerms, withSearchEngine: "Wikipedia")
        searchForTerms(searchTerms, withSearchEngine: "Yahoo")
    }

    private func waitForPotentialDebounce(tester: KIFUITestActor) {
        tester.waitForTimeInterval(0.3)
    }

    private func resetSuggestionsPrompt() {
        NSNotificationCenter.defaultCenter().postNotificationName("SearchEnginesPromptReset", object: nil)
    }

    private func getFirstSuggestionButton(tester: KIFUITestActor) -> UIButton? {
        return tester.waitForViewWithAccessibilityHint(HintSuggestionButton) as? UIButton
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        resetSuggestionsPrompt()
        do {
            try tester().tryFindingTappableViewWithAccessibilityLabel("Cancel")
            tester().tapViewWithAccessibilityLabel("Cancel")
        } catch _ {
        }
        BrowserUtils.clearHistoryItems(tester())
        BrowserUtils.resetToAboutHome(tester())
    }
}
