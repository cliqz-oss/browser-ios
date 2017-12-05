/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import OnePasswordExtension

private let log = Logger.browserLogger

class ShareExtensionHelper: NSObject {
    fileprivate weak var selectedTab: Tab?

    fileprivate let selectedURL: URL
    fileprivate var onePasswordExtensionItem: NSExtensionItem!
    fileprivate let activities: [UIActivity]

    init(url: URL, tab: Tab?, activities: [UIActivity]) {
        self.selectedURL = url
        self.selectedTab = tab
        self.activities = activities
    }

    func createActivityViewController(_ completionHandler: @escaping (Bool) -> Void) -> UIActivityViewController {
        var activityItems = [AnyObject]()

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = selectedTab?.url?.absoluteString ?? selectedURL.absoluteString
        printInfo.outputType = .general
        activityItems.append(printInfo)

        if let tab = selectedTab {
            activityItems.append(TabPrintPageRenderer(tab: tab))
        }

        if let title = selectedTab?.title {
            activityItems.append(TitleActivityItemProvider(title: title))
        }
        
        if #available(iOS 11, *) {
            if let displayURL = selectedTab?.displayURL {
                activityItems.append(displayURL.absoluteString as AnyObject)
            } else {
                activityItems.append(selectedURL.absoluteString as AnyObject)
            }
        } else {
            activityItems.append(self)
        }

        // Cliqz: Added footer to shared urls
        let footer = NSLocalizedString("Shared with CLIQZ for iOS", tableName: "Cliqz", comment: "Share footer")
        activityItems.append(FooterActivityItemProvider(footer: "\n\n\(footer)"))
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)

        
        // Hide 'Add to Reading List' which currently uses Safari.
        // We would also hide View Later, if possible, but the exclusion list doesn't currently support
        // third-party activity types (rdar://19430419).
        activityViewController.excludedActivityTypes = [
            UIActivityType.addToReadingList,
        ]

        // This needs to be ready by the time the share menu has been displayed and
        // activityViewController(activityViewController:, activityType:) is called,
        // which is after the user taps the button. So a million cycles away.
        if (ShareExtensionHelper.isPasswordManagerExtensionAvailable()) {
            findLoginExtensionItem()
        }

        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if !completed {
                completionHandler(completed)
                return
            }

            if self.isPasswordManagerActivityType(activityType.map { $0.rawValue }) {
                if let logins = returnedItems {
                    self.fillPasswords(logins as [AnyObject])
                }
            }

            completionHandler(completed)
        }
        return activityViewController
    }
}

extension ShareExtensionHelper: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        if let displayURL = selectedTab?.displayURL {
            return displayURL
        }
        return selectedURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if isPasswordManagerActivityType(activityType.rawValue) {
            return onePasswordExtensionItem
        } else {
            // Return the URL for the selected tab. If we are in reader view then decode
            // it so that we copy the original and not the internal localhost one.
            if let url = selectedTab?.displayURL, ReaderModeUtils.isReaderModeURL(url) {
                return ReaderModeUtils.decodeURL(url)
            }
            return selectedTab?.displayURL ?? selectedURL
        }
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        // Because of our UTI declaration, this UTI now satisfies both the 1Password Extension and the usual NSURL for Share extensions.
        return "org.appextension.fill-browser-action"
    }
}

private extension ShareExtensionHelper {
    static func isPasswordManagerExtensionAvailable() -> Bool {
        return OnePasswordExtension.shared().isAppExtensionAvailable()
    }

    func isPasswordManagerActivityType(_ activityType: String?) -> Bool {
        if (!ShareExtensionHelper.isPasswordManagerExtensionAvailable()) {
            return false
        }
        // A 'password' substring covers the most cases, such as pwsafe and 1Password.
        // com.agilebits.onepassword-ios.extension
        // com.app77.ios.pwsafe2.find-login-action-password-actionExtension
        // If your extension's bundle identifier does not contain "password", simply submit a pull request by adding your bundle identifier.
        return (activityType?.range(of: "password") != nil)
            || (activityType == "com.lastpass.ilastpass.LastPassExt")

    }

    func findLoginExtensionItem() {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        if selectedWebView.url?.absoluteString == nil {
            return
        }

        // Add 1Password to share sheet
        OnePasswordExtension.shared().createExtensionItem(forWebView: selectedWebView, completion: {(extensionItem, error) -> Void in
            if extensionItem == nil {
                log.error("Failed to create the password manager extension item: \(error).")
                return
            }

            // Set the 1Password extension item property
            self.onePasswordExtensionItem = extensionItem
        })
    }

    func fillPasswords(_ returnedItems: [AnyObject]) {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        OnePasswordExtension.shared().fillReturnedItems(returnedItems, intoWebView: selectedWebView, completion: { (success, returnedItemsError) -> Void in
            if !success {
                log.error("Failed to fill item into webview: \(returnedItemsError).")
            }
        })
    }
}
