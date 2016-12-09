/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Shared
import Foundation
import XCTest
import libPhoneNumber

class PhoneNumberFormatterTests: XCTestCase {

    // MARK: - Country Code Guessing

    func testUsesCarrierForGuessingCountryCode() {
        let utilMock = PhoneNumberUtilMock(carrierCountryCode: "DE")
        let formatter = PhoneNumberFormatter(util: utilMock)
        XCTAssertEqual(formatter.guessCurrentCountryCode(NSLocale(localeIdentifier: "en_US")), "DE")
    }

    func testFallsBackToSpecifiedLocaleForGuessingCountryCode() {
        let utilMock = PhoneNumberUtilMock(carrierCountryCode: NB_UNKNOWN_REGION)
        let formatter = PhoneNumberFormatter(util: utilMock)
        XCTAssertEqual(formatter.guessCurrentCountryCode(NSLocale(localeIdentifier: "en_US")), "US")
    }

    // MARK: - Format Selection

    func testSelectsNationalFormatWithoutCountryCode() {
        let number = NBPhoneNumber(countryCodeSource: .FROM_DEFAULT_COUNTRY)
        let formatter = PhoneNumberFormatter()
        XCTAssertEqual(formatter.formatForNumber(number), NBEPhoneNumberFormat.NATIONAL)
    }

    func testSelectsInternationalFormatWithCountryCode() {
        let number = NBPhoneNumber(countryCodeSource: .FROM_NUMBER_WITH_PLUS_SIGN)
        let formatter = PhoneNumberFormatter()
        XCTAssertEqual(formatter.formatForNumber(number), NBEPhoneNumberFormat.INTERNATIONAL)
    }

    // MARK: - Formatting

    func testReturnsInputStringWhenParsingFails() {
        let utilMock = PhoneNumberUtilMock(failOnParsing: true)
        let formatter = PhoneNumberFormatter(util: utilMock)
        let phoneNumber = "123456789"
        XCTAssertEqual(formatter.formatPhoneNumber(phoneNumber), phoneNumber)
        XCTAssertTrue(utilMock.didParse)
        XCTAssertFalse(utilMock.didFormat)
    }

    func testReturnsInputStringWhenValidatingFails() {
        let utilMock = PhoneNumberUtilMock(failOnValidating: true)
        let formatter = PhoneNumberFormatter(util: utilMock)
        let phoneNumber = "123456789"
        XCTAssertEqual(formatter.formatPhoneNumber(phoneNumber), phoneNumber)
        XCTAssertTrue(utilMock.didParse)
        XCTAssertTrue(utilMock.didValidate)
        XCTAssertFalse(utilMock.didFormat)
    }

    func testReturnsInputStringWhenFormattingFails() {
        let utilMock = PhoneNumberUtilMock(failOnFormatting: true)
        let formatter = PhoneNumberFormatter(util: utilMock)
        let phoneNumber = "123456789"
        XCTAssertEqual(formatter.formatPhoneNumber(phoneNumber), phoneNumber)
        XCTAssertTrue(utilMock.didParse)
        XCTAssertTrue(utilMock.didValidate)
        XCTAssertTrue(utilMock.didFormat)
    }

    func testFormatsNumber() {
        let utilMock = PhoneNumberUtilMock()
        let formatter = PhoneNumberFormatter(util: utilMock)
        let phoneNumber = "123456789"
        XCTAssertEqual(formatter.formatPhoneNumber(phoneNumber), utilMock.formattedPhoneNumber)
        XCTAssertTrue(utilMock.didParse)
        XCTAssertTrue(utilMock.didValidate)
        XCTAssertTrue(utilMock.didFormat)
    }

}

// MARK: - Mocks & Helpers

private class PhoneNumberUtilMock: NBPhoneNumberUtil {

    let formattedPhoneNumber = "(123) 456789"

    private let carrierCountryCode: String?
    private let failOnParsing: Bool
    private let failOnValidating: Bool
    private let failOnFormatting: Bool

    private var didParse = false
    private var didValidate = false
    private var didFormat = false

    init(carrierCountryCode: String? = nil, failOnParsing: Bool = false, failOnValidating: Bool = false, failOnFormatting: Bool = false) {
        self.carrierCountryCode = carrierCountryCode
        self.failOnParsing = failOnParsing
        self.failOnValidating = failOnValidating
        self.failOnFormatting = failOnFormatting
    }

    private override func countryCodeByCarrier() -> String! {
        return carrierCountryCode ?? NB_UNKNOWN_REGION
    }

    private override func parseAndKeepRawInput(numberToParse: String!, defaultRegion: String!) throws -> NBPhoneNumber {
        didParse = true
        if failOnParsing {
            throw NSError(domain: "foo", code: 1, userInfo: nil)
        }
        return NBPhoneNumber(countryCodeSource: .FROM_NUMBER_WITH_PLUS_SIGN)
    }

    private override func isValidNumber(number: NBPhoneNumber!) -> Bool {
        didValidate = true
        return !failOnValidating
    }

    private override func format(phoneNumber: NBPhoneNumber!, numberFormat: NBEPhoneNumberFormat) throws -> String {
        didFormat = true
        if failOnFormatting {
            throw NSError(domain: "foo", code: 1, userInfo: nil)
        }
        return formattedPhoneNumber
    }

}

extension NBPhoneNumber {

    convenience init(countryCodeSource: NBECountryCodeSource) {
        self.init()
        self.countryCodeSource = NSNumber(integer: countryCodeSource.rawValue)
    }

}
