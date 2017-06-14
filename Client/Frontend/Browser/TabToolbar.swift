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
    // Cliqz: Add Tabs button
    var tabsButton: CliqzTabsButton { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateBookmarkStatus(_ isBookmarked: Bool)
    func updateReloadStatus(_ isLoading: Bool)
    func updatePageStatus(_ isWebPage: Bool)
    func updateTabStatus(_ keepOpen: Bool)
}

@objc
protocol TabToolbarDelegate: class {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressShare(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressHomePage(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    
    // Cliqz: Add delegate methods for tabs button
    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

@objc
open class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol

    let ImageReload = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageReloadPressed = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageStop = UIImage.templateImageNamed("stop")
    let ImageStopPressed = UIImage.templateImageNamed("stopPressed")

    var buttonTintColor = UIColor.darkGray {
        didSet {
            setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
        }
    }

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, for: .normal)
                // Cliqz: Removed highlighted state - discussed with Sven
//                toolbar.stopReloadButton.setImage(ImageStopPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, for: .normal)
                // Cliqz: Removed highlighted state - discussed with Sven
//                toolbar.stopReloadButton.setImage(ImageReloadPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
            }
        }
    }

    fileprivate func setTintColor(_ color: UIColor, forButtons buttons: [UIButton]) {
        buttons.forEach { $0.tintColor = color }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("bottomNav-back"), for: .normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.backButton.setImage(UIImage(named: "bottomNav-backEngaged"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBack(_:)))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBack), for: UIControlEvents.touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("bottomNav-forward"), for: .normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.forwardButton.setImage(UIImage(named: "bottomNav-forwardEngaged"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressForward(_:)))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickForward), for: UIControlEvents.touchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("bottomNav-refresh"), for: .normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.stopReloadButton.setImage(UIImage(named: "bottomNav-refreshEngaged"), forState: .Highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressStopReload(_:)))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickStopReload), for: UIControlEvents.touchUpInside)

        toolbar.shareButton.setImage(UIImage.templateImageNamed("bottomNav-send"), for: .normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.shareButton.setImage(UIImage(named: "bottomNav-sendEngaged"), forState: .Highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the tab toolbar Share button")
        toolbar.shareButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickShare), for: UIControlEvents.touchUpInside)

        toolbar.homePageButton.setImage(UIImage.templateImageNamed("menu-Home"), for: .normal)
        // Cliqz: Removed highlighted state - discussed with Sven
//        toolbar.homePageButton.setImage(UIImage(named: "menu-Home-Engaged"), forState: .Highlighted)
        toolbar.homePageButton.accessibilityLabel = NSLocalizedString("Toolbar.OpenHomePage.AccessibilityLabel", value: "Homepage", comment: "Accessibility Label for the tab toolbar Homepage button")
        toolbar.homePageButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickHomePage), for: UIControlEvents.touchUpInside)
        
        // Cliqz: Add tabs button
        toolbar.tabsButton.setImage(UIImage(named: "tabs"), for: .normal)
        toolbar.tabsButton.setImage(UIImage(named: "tabs_selected"), for: .selected)
        toolbar.tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the tab toolbar.")
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressTabs(_:)))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)
        toolbar.tabsButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickTabs), for: UIControlEvents.touchUpInside)
        

        if AppConstants.MOZ_MENU {
            toolbar.menuButton.contentMode = UIViewContentMode.center
            toolbar.menuButton.setImage(UIImage.templateImageNamed("bottomNav-menu"), for: .normal)
            toolbar.menuButton.accessibilityLabel = AppMenuConfiguration.MenuButtonAccessibilityLabel
            toolbar.menuButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickMenu), for: UIControlEvents.touchUpInside)
            toolbar.menuButton.accessibilityIdentifier = "TabToolbar.menuButton"

        } else {
            toolbar.bookmarkButton.contentMode = UIViewContentMode.center
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmark"), for: .normal)
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarked"), for: .selected)
            // Cliqz: Removed highlighted state - discussed with Sven
//            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarkHighlighted"), forState: UIControlState.Highlighted)
            toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the tab toolbar Bookmark button")
            let longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBookmark(_:)))
            toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
            toolbar.bookmarkButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBookmark), for: UIControlEvents.touchUpInside)
        }

        setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
    }

    func SELdidClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func SELdidClickShare() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressShare(toolbar, button: toolbar.shareButton)
    }

    func SELdidClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func SELdidLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func SELdidClickBookmark() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBookmark(toolbar, button: toolbar.bookmarkButton)
    }

    func SELdidLongPressBookmark(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
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

    func SELdidLongPressStopReload(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began && !loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func SELdidClickHomePage() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressHomePage(toolbar, button: toolbar.homePageButton)
    }

    func updateReloadStatus(_ isLoading: Bool) {
        loading = isLoading
    }
    
    
    
    // Cliqz: Add actions for tabs button
    func SELdidClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }
    
    func SELdidLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.backButton)
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
    // Cliqz: Add tabs button
    let tabsButton: CliqzTabsButton

    var helper: TabToolbarHelper?

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.buttonTintColor = UIColor.darkGray
        themes[Theme.NormalMode] = theme
        
        return themes
    }()

    // This has to be here since init() calls it
    fileprivate override init(frame: CGRect) {
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
        // Cliqz: Add Tabs button
        tabsButton = CliqzTabsButton()
        tabsButton.accessibilityIdentifier = "TabToolbar.TabsButton"
        
        if AppConstants.MOZ_MENU {
            actionButtons = [backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton]
        } else {
            // Cliqz: remove Reload button and add tabs & new tab buttons
//            actionButtons = [backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton]
            actionButtons = [backButton, forwardButton, shareButton, bookmarkButton, tabsButton]
        }

        super.init(frame: frame)

        self.helper = TabToolbarHelper(toolbar: self)

        if AppConstants.MOZ_MENU {
            addButtons(backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton)
        } else {
            // Cliqz: remove Reload button and add tabs button
//            addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton)
            addButtons(backButton, forwardButton, shareButton, bookmarkButton, tabsButton)
        }

        accessibilityNavigationStyle = .combined
        accessibilityLabel = NSLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateBookmarkStatus(_ isBookmarked: Bool) {
        bookmarkButton.isSelected = isBookmarked
    }

    func updateReloadStatus(_ isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
    }

    func updatePageStatus(_ isWebPage: Bool) {
        if !AppConstants.MOZ_MENU {
            bookmarkButton.isEnabled = isWebPage
        }
        stopReloadButton.isEnabled = isWebPage
        shareButton.isEnabled = isWebPage
    }
    
    func updateTabStatus(_ keepOpen: Bool) {
        tabsButton.isSelected = keepOpen
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    fileprivate func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: start.x, y: start.y))
        context.addLine(to: CGPoint(x: end.x, y: end.y))
        context.strokePath()
    }
    
    // Cliqz: update tabs button in the bottom toolbar
    func updateTabCount(_ count: Int) {
        self.tabsButton.accessibilityValue = count.description
        self.tabsButton.title.text = count.description
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
    func applyTheme(_ themeName: String) {
        guard let theme = TabToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        actionButtonTintColor = theme.buttonTintColor!
        tabsButton.applyTheme(themeName)
    }
}

extension TabToolbar: AppStateDelegate {
    func appDidUpdateState(_ state: AppState) {

        // Cliqz: disable home page changes as it movies share button to the end of the button list
        /*
        let isPrivate = Accessors.isPrivate(state)
        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

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
