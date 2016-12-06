/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

@objc
protocol TabToolbarProtocol {
    weak var tabToolbarDelegate: TabToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var bookmarkButton: UIButton { get }
    var menuButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }
    var stopReloadButton: UIButton { get }
    var homePageButton: UIButton { get }
    var actionButtons: [UIButton] { get }
    // Cliqz: Add new Tab button
    var newTabButton: UIButton { get }

    func updateBackStatus(canGoBack: Bool)
    func updateForwardStatus(canGoForward: Bool)
    func updateBookmarkStatus(isBookmarked: Bool)
    func updateReloadStatus(isLoading: Bool)
    func updatePageStatus(isWebPage isWebPage: Bool)
}

@objc
protocol TabToolbarDelegate: class {
    func tabToolbarDidPressBack(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressBookmark(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBookmark(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressShare(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressHomePage(tabToolbar: TabToolbarProtocol, button: UIButton)
    
    // Cliqz: Add delegate methods for new tab button
    func tabToolbarDidPressNewTab(tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressNewTab(tabToolbar: TabToolbarProtocol, button: UIButton)
}

@objc
public class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol

    let ImageReload = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageReloadPressed = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageStop = UIImage.templateImageNamed("stop")
    let ImageStopPressed = UIImage.templateImageNamed("stopPressed")

    var buttonTintColor = UIColor.darkGrayColor() {
        didSet {
            setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
        }
    }

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, forState: .Normal)
                // Cliqz: Removed highlighted state - discussed with Sven
//                toolbar.stopReloadButton.setImage(ImageStopPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, forState: .Normal)
                // Cliqz: Removed highlighted state - discussed with Sven
//                toolbar.stopReloadButton.setImage(ImageReloadPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
            }
        }
    }

    private func setTintColor(color: UIColor, forButtons buttons: [UIButton]) {
        buttons.forEach { $0.tintColor = color }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("bottomNav-back"), forState: .Normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.backButton.setImage(UIImage(named: "bottomNav-backEngaged"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBack(_:)))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBack), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("bottomNav-forward"), forState: .Normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.forwardButton.setImage(UIImage(named: "bottomNav-forwardEngaged"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressForward(_:)))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickForward), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("bottomNav-refresh"), forState: .Normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.stopReloadButton.setImage(UIImage(named: "bottomNav-refreshEngaged"), forState: .Highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressStopReload(_:)))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickStopReload), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.shareButton.setImage(UIImage.templateImageNamed("bottomNav-send"), forState: .Normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.shareButton.setImage(UIImage(named: "bottomNav-sendEngaged"), forState: .Highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the tab toolbar Share button")
        toolbar.shareButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickShare), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.homePageButton.setImage(UIImage.templateImageNamed("menu-Home"), forState: .Normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.homePageButton.setImage(UIImage(named: "menu-Home-Engaged"), forState: .Highlighted)
        toolbar.homePageButton.accessibilityLabel = NSLocalizedString("Toolbar.OpenHomePage.AccessibilityLabel", value: "Homepage", comment: "Accessibility Label for the tab toolbar Homepage button")
        toolbar.homePageButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickHomePage), forControlEvents: UIControlEvents.TouchUpInside)
        
        
        // Cliqz: Add new tab button
        toolbar.newTabButton.setImage(UIImage.templateImageNamed("bottomNav-NewTab"), forState: .Normal)
        toolbar.newTabButton.accessibilityLabel = NSLocalizedString("New tab", comment: "Accessibility label for the New tab button in the tab toolbar.")
        let longPressGestureNewTabButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressNewTab(_:)))
        toolbar.newTabButton.addGestureRecognizer(longPressGestureNewTabButton)
        toolbar.newTabButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickNewTab), forControlEvents: UIControlEvents.TouchUpInside)
        

        if AppConstants.MOZ_MENU {
            toolbar.menuButton.contentMode = UIViewContentMode.Center
            toolbar.menuButton.setImage(UIImage.templateImageNamed("bottomNav-menu"), forState: .Normal)
            toolbar.menuButton.accessibilityLabel = AppMenuConfiguration.MenuButtonAccessibilityLabel
            toolbar.menuButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickMenu), forControlEvents: UIControlEvents.TouchUpInside)
            toolbar.menuButton.accessibilityIdentifier = "TabToolbar.menuButton"

        } else {
            toolbar.bookmarkButton.contentMode = UIViewContentMode.Center
            toolbar.bookmarkButton.setImage(UIImage.templateImageNamed("bookmark"), forState: .Normal)
            toolbar.bookmarkButton.setImage(UIImage.templateImageNamed("bookmarked"), forState: UIControlState.Selected)
            // Cliqz: Removed highlighted state - discussed with Sven
//            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarkHighlighted"), forState: UIControlState.Highlighted)
            toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the tab toolbar Bookmark button")
            let longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBookmark(_:)))
            toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
            toolbar.bookmarkButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBookmark), forControlEvents: UIControlEvents.TouchUpInside)
        }

        setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
    }

    func SELdidClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidLongPressBack(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func SELdidClickShare() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressShare(toolbar, button: toolbar.shareButton)
    }

    func SELdidClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func SELdidLongPressForward(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func SELdidClickBookmark() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBookmark(toolbar, button: toolbar.bookmarkButton)
    }

    func SELdidLongPressBookmark(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBookmark(toolbar, button: toolbar.bookmarkButton)
        }
    }

    func SELdidClickMenu() {
		// Cliqz: Removed menu button as we don't need it
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.menuButton)
    }

    func SELdidClickStopReload() {
        if loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressStop(toolbar, button: toolbar.stopReloadButton)
        } else {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func SELdidLongPressStopReload(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began && !loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func SELdidClickHomePage() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressHomePage(toolbar, button: toolbar.homePageButton)
    }

    func updateReloadStatus(isLoading: Bool) {
        loading = isLoading
    }
    // Cliqz: Add actions for new tab button
    
    func SELdidClickNewTab() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressNewTab(toolbar, button: toolbar.backButton)
    }
    
    func SELdidLongPressNewTab(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressNewTab(toolbar, button: toolbar.backButton)
        }
    }
}

class TabToolbar: Toolbar, TabToolbarProtocol {
    weak var tabToolbarDelegate: TabToolbarDelegate?

    let shareButton: UIButton
    let bookmarkButton: UIButton
    let menuButton: UIButton
    let forwardButton: UIButton
    let backButton: UIButton
    let stopReloadButton: UIButton
    let homePageButton: UIButton
    let actionButtons: [UIButton]
    // Cliqz: Add new tab button
    let newTabButton: UIButton

    var helper: TabToolbarHelper?

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.buttonTintColor = UIColor.darkGrayColor()
        themes[Theme.NormalMode] = theme
        
        return themes
    }()

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        backButton.accessibilityIdentifier = "TabToolbar.backButton"
        forwardButton = UIButton()
        forwardButton.accessibilityIdentifier = "TabToolbar.forwardButton"
        stopReloadButton = UIButton()
        stopReloadButton.accessibilityIdentifier = "TabToolbar.stopReloadButton"
        shareButton = UIButton()
        shareButton.accessibilityIdentifier = "TabToolbar.shareButton"
        bookmarkButton = UIButton()
        bookmarkButton.accessibilityIdentifier = "TabToolbar.bookmarkButton"
        menuButton = UIButton()
        menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        homePageButton = UIButton()
        menuButton.accessibilityIdentifier = "TabToolbar.homePageButton"
        // Cliqz: Add new Tab button
        newTabButton = UIButton()
        newTabButton.accessibilityIdentifier = "TabToolbar.newTabButton"
        
        if AppConstants.MOZ_MENU {
            actionButtons = [backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton]
        } else {
            // Cliqz: remove Reload button and add new tab button
//            actionButtons = [backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton]
            actionButtons = [backButton, forwardButton, shareButton, bookmarkButton, newTabButton]
        }

        super.init(frame: frame)

        self.helper = TabToolbarHelper(toolbar: self)

        if AppConstants.MOZ_MENU {
            addButtons(backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton)
        } else {
            // Cliqz: remove Reload button and add new tab button
//            addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton)
            addButtons(backButton, forwardButton, shareButton, bookmarkButton, newTabButton)
        }

        accessibilityNavigationStyle = .Combined
        accessibilityLabel = NSLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateForwardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateBookmarkStatus(isBookmarked: Bool) {
        bookmarkButton.selected = isBookmarked
    }

    func updateReloadStatus(isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
    }

    func updatePageStatus(isWebPage isWebPage: Bool) {
        if !AppConstants.MOZ_MENU {
            bookmarkButton.enabled = isWebPage
        }
        stopReloadButton.enabled = isWebPage
        shareButton.enabled = isWebPage
    }

    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    private func drawLine(context: CGContextRef, start: CGPoint, end: CGPoint) {
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().colorWithAlphaComponent(0.05).CGColor)
        CGContextSetLineWidth(context, 2)
        CGContextMoveToPoint(context, start.x, start.y)
        CGContextAddLineToPoint(context, end.x, end.y)
        CGContextStrokePath(context)
    }
}

// MARK: UIAppearance
extension TabToolbar {
    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }
}

extension TabToolbar: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = TabToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        actionButtonTintColor = theme.buttonTintColor!
    }
}

extension TabToolbar: AppStateDelegate {
    func appDidUpdateState(state: AppState) {
        let isPrivate = Accessors.isPrivate(state)
        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

        // Cliqz: disable home page changes as it movies share button to the end of the button list
        /*
        let showHomepage = !HomePageAccessors.isButtonInMenu(state)
        homePageButton.removeFromSuperview()
        shareButton.removeFromSuperview()

        if showHomepage {
            homePageButton.enabled = HomePageAccessors.isButtonEnabled(state)
            addButtons(homePageButton)
        } else {
            addButtons(shareButton)
        }
         */
        updateConstraints()
    }
}
