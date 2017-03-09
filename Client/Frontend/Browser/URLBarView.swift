/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

struct URLBarViewUX {
    static let TextFieldBorderColor = UIColor(rgb: 0xBBBBBB)
    static let TextFieldActiveBorderColor = UIColor(rgb: 0x4A90E2)
    static let TextFieldContentInset = UIOffsetMake(9, 5)
    static let LocationLeftPadding: CGFloat = 10
    static let LocationHeight = 28
    static let ExpandedLocationHeight = 35
    static let LocationContentOffset: CGFloat = 8
    static let TextFieldCornerRadius: CGFloat = 3
    static let TextFieldBorderWidth: CGFloat = 1
    // offset from edge of tabs button
    static let URLBarCurveOffset: CGFloat = 14
    static let URLBarCurveOffsetLeft: CGFloat = -10
    // Cliqz: added offset between buttons
    static let URLBarButtonOffset: CGFloat = 5
    // buffer so we dont see edges when animation overshoots with spring
    static let URLBarCurveBounceBuffer: CGFloat = 8
    static let ProgressTintColor = UIColor(red:1, green:0.32, blue:0, alpha:1)

    static let TabsButtonRotationOffset: CGFloat = 1.5
    static let TabsButtonHeight: CGFloat = 18.0
    static let ToolbarButtonInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModeLocationBorderColor
        theme.activeBorderColor = UIConstants.PrivateModePurple
        theme.tintColor = UIConstants.PrivateModePurple
        theme.textColor = UIConstants.PrivateModeTextColor //UIColor.whiteColor()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        // Cliqz: Set URLBar backgroundColor because of requirements
        theme.backgroundColor = UIConstants.PrivateModeBackgroundColor
        
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        // Cliqz: Removed TextField border because of requirements
        theme.borderColor = UIColor.clearColor()
        theme.activeBorderColor = UIColor.clearColor()
        theme.tintColor = ProgressTintColor
        theme.textColor = UIConstants.NormalModeTextColor //UIColor.blackColor()
        // Cliqz: Changed button tint color to black in the upper toolbar (URLBar)
        theme.buttonTintColor = UIColor.blackColor()
        // Cliqz: Set URLBar backgroundColor because of requirements
        theme.backgroundColor = UIConstants.AppBackgroundColor.colorWithAlphaComponent(1)
        
        themes[Theme.NormalMode] = theme

        return themes
    }()

    static func backgroundColorWithAlpha(alpha: CGFloat) -> UIColor {
        return UIConstants.AppBackgroundColor.colorWithAlphaComponent(alpha)
    }
}

protocol URLBarDelegate: class {
    func urlBarDidPressTabs(urlBar: URLBarView)
    func urlBarDidPressReaderMode(urlBar: URLBarView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func urlBarDidLongPressReaderMode(urlBar: URLBarView) -> Bool
    func urlBarDidPressStop(urlBar: URLBarView)
    func urlBarDidPressReload(urlBar: URLBarView)
    func urlBarDidEnterOverlayMode(urlBar: URLBarView)
    func urlBarDidLeaveOverlayMode(urlBar: URLBarView)
    func urlBarDidLongPressLocation(urlBar: URLBarView)
    func urlBarLocationAccessibilityActions(urlBar: URLBarView) -> [UIAccessibilityCustomAction]?
    func urlBarDidPressScrollToTop(urlBar: URLBarView)
    func urlBar(urlBar: URLBarView, didEnterText text: String)
    func urlBar(urlBar: URLBarView, didSubmitText text: String)
    func urlBarDisplayTextForURL(url: NSURL?) -> String?
    
    
    // Cliqz: Add delegate methods for new tab button
    func urlBarDidPressNewTab(urlBar: URLBarView, button: UIButton)
    // Cliqz: Added delegate method for antitracking button
    func urlBarDidClickAntitracking(urlBar: URLBarView, trackersCount: Int, status: String)
    // Cliqz: Added delegate method for notifing deletge that search field was cleared
    func urlBarDidClearSearchField(urlBar: URLBarView, oldText: String?)
}

class URLBarView: UIView {
    // Additional UIAppearance-configurable properties
    dynamic var locationBorderColor: UIColor = URLBarViewUX.TextFieldBorderColor {
        didSet {
            if !inOverlayMode {
                locationContainer.layer.borderColor = locationBorderColor.CGColor
            }
        }
    }
    dynamic var locationActiveBorderColor: UIColor = URLBarViewUX.TextFieldActiveBorderColor {
        didSet {
            if inOverlayMode {
                locationContainer.layer.borderColor = locationActiveBorderColor.CGColor
            }
        }
    }

    weak var delegate: URLBarDelegate?
    weak var tabToolbarDelegate: TabToolbarDelegate?
    var helper: TabToolbarHelper?
    var isTransitioning: Bool = false {
        didSet {
            if isTransitioning {
                // Cancel any pending/in-progress animations related to the progress bar
                self.progressBar.setProgress(1, animated: false)
                self.progressBar.alpha = 0.0
            }
        }
    }

    private var currentTheme: String = Theme.NormalMode

    var toolbarIsShowing = false

    internal var locationTextField: ToolbarTextField?

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode). Overlay mode
    /// is *not* tied to the location text field's editing state; for instance, when selecting
    /// a panel, the first responder will be resigned, yet the overlay mode UI is still active.
    var inOverlayMode = false

    lazy var locationView: TabLocationView = {
        let locationView = TabLocationView()
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.readerModeState = ReaderModeState.Unavailable
        locationView.delegate = self
        return locationView
    }()

    lazy var locationContainer: UIView = {
        let locationContainer = UIView()
        locationContainer.translatesAutoresizingMaskIntoConstraints = false

        // Enable clipping to apply the rounded edges to subviews.
        locationContainer.clipsToBounds = true

        locationContainer.layer.borderColor = self.locationBorderColor.CGColor
        locationContainer.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth

        return locationContainer
    }()

    private lazy var progressBar: UIProgressView = {
        let progressBar = UIProgressView()
        progressBar.progressTintColor = URLBarViewUX.ProgressTintColor
        progressBar.alpha = 0
        progressBar.hidden = true
        return progressBar
    }()

    private lazy var cancelButton: UIButton = {
        // Cliz: use regular button with icon for cancel button
        let cancelButton = InsetButton()
        cancelButton.setImage(UIImage(named:"urlExpand"), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(URLBarView.SELdidClickCancel), forControlEvents: UIControlEvents.TouchUpInside)
        /*
        let cancelButton = InsetButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Label for Cancel button")
        cancelButton.setTitle(cancelTitle, forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIConstants.DefaultChromeFont
        cancelButton.addTarget(self, action: #selector(URLBarView.SELdidClickCancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.titleEdgeInsets = UIEdgeInsetsMake(10, 12, 10, 12)
        cancelButton.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        */
        
        cancelButton.alpha = 0
        return cancelButton
    }()

    private lazy var curveShape: CurveView = { return CurveView() }()

    private lazy var scrollToTopButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(URLBarView.SELtappedScrollToTopArea), forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    lazy var shareButton: UIButton = { return UIButton() }()

    lazy var menuButton: UIButton = { return UIButton() }()

    lazy var bookmarkButton: UIButton = { return UIButton() }()

    lazy var forwardButton: UIButton = { return UIButton() }()

    lazy var backButton: UIButton = { return UIButton() }()

    lazy var stopReloadButton: UIButton = { return UIButton() }()

    lazy var homePageButton: UIButton = { return UIButton() }()
    
    lazy var tabsButton: CliqzTabsButton = { return CliqzTabsButton() }()


    lazy var actionButtons: [UIButton] = {
		// Cliqz: Removed StopReloadButton
        return AppConstants.MOZ_MENU ? [self.shareButton, self.menuButton, self.forwardButton, self.backButton, self.stopReloadButton, self.homePageButton] : [self.shareButton, self.bookmarkButton, self.forwardButton, self.backButton, self.tabsButton]
    }()

    // Cliqz: Added to maintain tab count
    private var tabCount = 1

	// Cliqz: removed cloned tabs button due to removing tabs button animation
//    // Used to temporarily store the cloned button so we can respond to layout changes during animation
//    private weak var clonedTabsButton: CliqzTabsButton?

    private var rightBarConstraint: Constraint?
    private let defaultRightOffset: CGFloat = URLBarViewUX.URLBarCurveOffset - URLBarViewUX.URLBarCurveBounceBuffer

    var currentURL: NSURL? {
        get {
            return locationView.url
        }

        set(newURL) {
            if let url = newURL {
                if(url.host != currentURL?.host){
                    NSNotificationCenter.defaultCenter().postNotificationName(NotificationRefreshAntiTrackingButton, object: nil, userInfo: ["newURL":url])
                }
            }
            locationView.url = newURL
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = URLBarViewUX.backgroundColorWithAlpha(0)
		// Cliqz: Commented extra curveView accroding to requirements.
//        addSubview(curveShape)
        addSubview(scrollToTopButton)

        addSubview(progressBar)
        // Cliqz: Add tabs button
        addSubview(tabsButton)
        addSubview(cancelButton)

        addSubview(shareButton)
        if AppConstants.MOZ_MENU {
            addSubview(menuButton)
            addSubview(homePageButton)
        } else {
            addSubview(bookmarkButton)
        }
        addSubview(forwardButton)
        addSubview(backButton)
//        addSubview(stopReloadButton)

        locationContainer.addSubview(locationView)
        addSubview(locationContainer)

        helper = TabToolbarHelper(toolbar: self)
        setupConstraints()

        // Make sure we hide any views that shouldn't be showing in non-overlay mode.
        updateViewsForOverlayModeAndToolbarChanges()
    }

    private func setupConstraints() {

        scrollToTopButton.snp_makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self.locationContainer)
        }

        progressBar.snp_makeConstraints { make in
            make.top.equalTo(self.snp_bottom)
            make.width.equalTo(self)
        }

        locationView.snp_makeConstraints { make in
            make.edges.equalTo(self.locationContainer)
        }

		cancelButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.trailing.equalTo(self)
            // Cliz: set the size of the cancel button as it is we changed it to a regular button with icon
            make.size.equalTo(UIConstants.ToolbarHeight)
		}

		// Cliqz: Moved Tabs button to the right of URL bar
		tabsButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.right.equalTo(self).offset(-URLBarViewUX.URLBarButtonOffset)
			make.size.equalTo(UIConstants.ToolbarHeight)
		}

		// Cliqz: Commented curveShape constraints because it's removed from view
//		curveShape.snp_makeConstraints { make in
//            make.top.left.bottom.equalTo(self)
//            self.rightBarConstraint = make.right.equalTo(self).constraint
//            self.rightBarConstraint?.updateOffset(defaultRightOffset)
//        }

		// Cliqz: changed backButtons constraint to position after tabs button
        backButton.snp_makeConstraints { make in
			make.centerY.equalTo(self)
            make.left.equalTo(self).offset(URLBarViewUX.URLBarButtonOffset)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        forwardButton.snp_makeConstraints { make in
            make.left.equalTo(self.backButton.snp_right).offset(URLBarViewUX.URLBarButtonOffset)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }

		// Cliqz: Removed stopReloadingButton from toolBar
/*
		stopReloadButton.snp_makeConstraints { make in
            make.left.equalTo(self.forwardButton.snp_right)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }
*/

        if AppConstants.MOZ_MENU {
            shareButton.snp_makeConstraints { make in
                make.right.equalTo(self.menuButton.snp_left)
                make.centerY.equalTo(self)
                make.size.equalTo(backButton)
            }
            
            homePageButton.snp_makeConstraints { make in
                make.center.equalTo(shareButton)
                make.size.equalTo(shareButton)
            }
            
            menuButton.snp_makeConstraints { make in
                make.right.equalTo(self.tabsButton.snp_left).offset(URLBarViewUX.URLBarCurveOffsetLeft)
                make.centerY.equalTo(self)
                make.size.equalTo(backButton)
            }
        } else {
			
            shareButton.snp_makeConstraints { make in
                // Cliqz: commented the left constaints as this will be overriden in CliqzURLBarView subclass
//                make.left.equalTo(self.forwardButton.snp_right)
                make.centerY.equalTo(self)
                make.size.equalTo(backButton)
            }
            
            // Cliqz: Changed Bookmark button position, next to back button
            bookmarkButton.snp_makeConstraints { make in
//                make.right.equalTo(self.tabsButton.snp_left).offset(URLBarViewUX.URLBarCurveOffsetLeft)
				make.left.equalTo(self.forwardButton.snp_right).offset(URLBarViewUX.URLBarButtonOffset)
                make.centerY.equalTo(self)
                make.size.equalTo(backButton)
            }
        }
	}

    override func updateConstraints() {
        super.updateConstraints()
        if inOverlayMode {
            // In overlay mode, we always show the location view full width
            self.locationContainer.snp_remakeConstraints { make in
				// Cliqz: Changed locationContainer's constraints to align with new buttons
                
                make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                make.trailing.equalTo(self.cancelButton.snp_leading)
//                make.height.equalTo(URLBarViewUX.LocationHeight)
                make.height.equalTo(URLBarViewUX.ExpandedLocationHeight)
                make.centerY.equalTo(self)
                
            }
			// Cliqz: Moved Tabs button to the left side of URLbar
			tabsButton.snp_remakeConstraints { make in
				make.centerY.equalTo(self.locationContainer)
				make.right.equalTo(self).offset(-URLBarViewUX.URLBarButtonOffset)
				make.size.equalTo(UIConstants.ToolbarHeight)
			}
        } else {
            self.locationContainer.snp_remakeConstraints { make in
				// Cliqz: Changed locationContainer's constraints to align with new buttons
				
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
					make.leading.equalTo(self.bookmarkButton.snp_trailing).offset(URLBarViewUX.URLBarButtonOffset)
                    make.trailing.equalTo(self.shareButton.snp_leading).offset(-URLBarViewUX.URLBarButtonOffset)
                } else {
                    // Otherwise, left align the location view
                    /*
                    make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                    make.trailing.equalTo(self.tabsButton.snp_leading).offset(-14)
                    */
					make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                    make.trailing.equalTo(self).offset(-URLBarViewUX.LocationLeftPadding)
                    make.height.equalTo(URLBarViewUX.LocationHeight)
                }
                make.height.equalTo(URLBarViewUX.LocationHeight)
                make.centerY.equalTo(self)
            }
			// Cliqz: Moved Tabs button to the left side of URLbar
			tabsButton.snp_remakeConstraints { make in
				make.centerY.equalTo(self.locationContainer)
                make.right.equalTo(self).offset(-URLBarViewUX.URLBarButtonOffset)
				make.size.equalTo(UIConstants.ToolbarHeight)
			}
        }
    }

    func createLocationTextField() {
        guard locationTextField == nil else { return }

        locationTextField = ToolbarTextField()

        guard let locationTextField = locationTextField else { return }
		
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.autocompleteDelegate = self
        //Cliqz: Changed the keyboard return button to default button `Return` as it dismiss the keyboard now instead of navigating to the search page
        locationTextField.keyboardType = .WebSearch
        locationTextField.autocorrectionType = UITextAutocorrectionType.No
        locationTextField.autocapitalizationType = UITextAutocapitalizationType.None
        locationTextField.returnKeyType = UIReturnKeyType.Go
		locationTextField.enablesReturnKeyAutomatically = true
		// Cliqz: Changed mode to always to use it also as cancel button
        locationTextField.clearButtonMode = UITextFieldViewMode.Always
        // Cliqz: Added left pading to the location field
        locationTextField.setLeftPading(5)
        locationTextField.font = UIConstants.DefaultChromeFont
        locationTextField.accessibilityIdentifier = "address"
        locationTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        locationTextField.attributedPlaceholder = self.locationView.placeholder
        locationContainer.addSubview(locationTextField)

        locationTextField.snp_makeConstraints { make in
            make.edges.equalTo(self.locationView.urlTextField)
        }
        
        locationTextField.applyTheme(currentTheme)
        let querySuggestionView = QuerySuggestionView()
        querySuggestionView.delegate = self
        locationTextField.inputAccessoryView = querySuggestionView
    }

    func removeLocationTextField() {
        locationTextField?.removeFromSuperview()
        locationTextField = nil
    }

    // Ideally we'd split this implementation in two, one URLBarView with a toolbar and one without
    // However, switching views dynamically at runtime is a difficult. For now, we just use one view
    // that can show in either mode.
    func setShowToolbar(shouldShow: Bool) {
        toolbarIsShowing = shouldShow
        setNeedsUpdateConstraints()
        // when we transition from portrait to landscape, calling this here causes
        // the constraints to be calculated too early and there are constraint errors
        if !toolbarIsShowing {
            updateConstraintsIfNeeded()
        }
        updateViewsForOverlayModeAndToolbarChanges()
    }

    func updateAlphaForSubviews(alpha: CGFloat) {
        self.tabsButton.alpha = alpha
        self.locationContainer.alpha = alpha
		// Cliqz: Commented because we should always have blue URLBar
//        self.backgroundColor = URLBarViewUX.backgroundColorWithAlpha(1 - alpha)
        self.actionButtons.forEach { $0.alpha = alpha }
    }

    func updateTabCount(count: Int, animated: Bool = true) {
        // Cliqz: update tabs button in the URLBar
        self.tabsButton.accessibilityValue = count.description
        self.tabsButton.title.text = count.description

        // Cliqz: commented the method as we use regular tabs button with no count
        /*
        // Cliqz: preserve last count to fix the problem of displaying worng tab count when closing opened tabs after sesstion timeout due to the animation
        tabCount = count
        
        let currentCount = self.tabsButton.titleLabel.text
        let infinity = "\u{221E}"
        let countToBe = (count < 100) ? count.description : infinity
        // only animate a tab count change if the tab count has actually changed
        if currentCount != countToBe {
            // Cliqz: remove tabs button animation
            self.tabsButton.titleLabel.text = self.tabCount.description
            self.tabsButton.accessibilityValue = self.tabCount.description
            
            if let _ = self.clonedTabsButton {
                self.clonedTabsButton?.layer.removeAllAnimations()
                self.clonedTabsButton?.removeFromSuperview()
                self.tabsButton.layer.removeAllAnimations()
            }
			
			// Cliqz: Changed tabsbutton type
            // make a 'clone' of the tabs button
            let newTabsButton = self.tabsButton.clone() as! CliqzTabsButton
            self.clonedTabsButton = newTabsButton
            newTabsButton.addTarget(self, action: #selector(URLBarView.SELdidClickAddTab), forControlEvents: UIControlEvents.TouchUpInside)
            newTabsButton.titleLabel.text = countToBe
            newTabsButton.accessibilityValue = countToBe
            addSubview(newTabsButton)
			// Cliqz: change tailing constraint to the left because we moved the button to the left side of
            newTabsButton.snp_makeConstraints { make in
                make.centerY.equalTo(self.locationContainer)
				make.left.equalTo(self)
                make.size.equalTo(UIConstants.ToolbarHeight)
            }
            
            newTabsButton.frame = tabsButton.frame
            
            // Instead of changing the anchorPoint of the CALayer, lets alter the rotation matrix math to be
            // a rotation around a non-origin point
            let frame = tabsButton.insideButton.frame
            let halfTitleHeight = CGRectGetHeight(frame) / 2
            
            var newFlipTransform = CATransform3DIdentity
            newFlipTransform = CATransform3DTranslate(newFlipTransform, 0, halfTitleHeight, 0)
            newFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            newFlipTransform = CATransform3DRotate(newFlipTransform, CGFloat(-M_PI_2), 1.0, 0.0, 0.0)
            newTabsButton.insideButton.layer.transform = newFlipTransform
            
            var oldFlipTransform = CATransform3DIdentity
            oldFlipTransform = CATransform3DTranslate(oldFlipTransform, 0, halfTitleHeight, 0)
            oldFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            oldFlipTransform = CATransform3DRotate(oldFlipTransform, CGFloat(M_PI_2), 1.0, 0.0, 0.0)
            
            let animate = {
                newTabsButton.insideButton.layer.transform = CATransform3DIdentity
                self.tabsButton.insideButton.layer.transform = oldFlipTransform
                self.tabsButton.insideButton.layer.opacity = 0
            }
            
            let completion: (Bool) -> Void = { finished in
                // remove the clone and setup the actual tab button
                newTabsButton.removeFromSuperview()
                
                self.tabsButton.insideButton.layer.opacity = 1
                self.tabsButton.insideButton.layer.transform = CATransform3DIdentity
                self.tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar")

                // Cliqz: always update tabs button title because finish is always equal false due to unknown reasons, and display last tab count to fix the problem of displaying worng tab count when closing opened tabs after sesstion timeout due to the animation
                /*
                if finished {
                    self.tabsButton.titleLabel.text = countToBe
                    self.tabsButton.accessibilityValue = countToBe
                }
                */
                self.tabsButton.titleLabel.text = self.tabCount.description
                self.tabsButton.accessibilityValue = self.tabCount.description

            }
            
            if animated {
                UIView.animateWithDuration(1.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: animate, completion: completion)
            } else {
                completion(true)
            }
 
        }
        */
    }
    
    func updateProgressBar(progress: Float) {
        if progress == 1.0 {
            self.progressBar.setProgress(progress, animated: !isTransitioning)
            UIView.animateWithDuration(1.5, animations: {
                self.progressBar.alpha = 0.0
            }, completion: { finished in
                if finished {
                    self.progressBar.setProgress(0.0, animated: false)
                }
            })
        } else {
            if self.progressBar.alpha < 1.0 {
                self.progressBar.alpha = 1.0
            }
            self.progressBar.setProgress(progress, animated: (progress > progressBar.progress) && !isTransitioning)
        }
    }

    func updateReaderModeState(state: ReaderModeState) {
        locationView.readerModeState = state
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        locationTextField?.setAutocompleteSuggestion(suggestion)
    }

    func enterOverlayMode(locationText: String?, pasted: Bool) {
        createLocationTextField()
        
        // Cliqz: call removeCompletion on the locationTextField to fix the problem of not updating LocationTextField text to locationText if there was autocompleted text
        locationTextField?.removeCompletion()

        // Show the overlay mode UI, which includes hiding the locationView and replacing it
        // with the editable locationTextField.
        animateToOverlayState(overlayMode: true)

        delegate?.urlBarDidEnterOverlayMode(self)

        // Bug 1193755 Workaround - Calling becomeFirstResponder before the animation happens
        // won't take the initial frame of the label into consideration, which makes the label
        // look squished at the start of the animation and expand to be correct. As a workaround,
        // we becomeFirstResponder as the next event on UI thread, so the animation starts before we
        // set a first responder.
        if pasted {
            // Clear any existing text, focus the field, then set the actual pasted text.
            // This avoids highlighting all of the text.
            self.locationTextField?.text = ""
            dispatch_async(dispatch_get_main_queue()) {
                self.locationTextField?.becomeFirstResponder()
                self.locationTextField?.text = locationText
            }
        } else {
            // Copy the current URL to the editable text field, then activate it.
            self.locationTextField?.text = locationText
            dispatch_async(dispatch_get_main_queue()) {
                self.locationTextField?.becomeFirstResponder()
            }
        }
        
        
        // Cliqz: set the background of the URLBar to white so that the search text appear as expanded (emphasis the search)
        self.backgroundColor = UIColor.whiteColor()
    }

    func leaveOverlayMode(didCancel cancel: Bool = false) {

        // Cliqz: take the responsibility of dismissing keyboard of locationTextField to fix the sublinks problem by eliminating the race between resizing and click events
//        locationTextField?.resignFirstResponder()
        locationTextField?.enforceResignFirstResponder()
        animateToOverlayState(overlayMode: false, didCancel: cancel)
        delegate?.urlBarDidLeaveOverlayMode(self)
        
        // Cliqz: return back the current theme of the URLBar
        self.applyTheme(currentTheme)
    }

    func prepareOverlayAnimation() {
        // Make sure everything is showing during the transition (we'll hide it afterwards).
        self.bringSubviewToFront(self.locationContainer)
        self.cancelButton.hidden = false
        self.progressBar.hidden = false
        if AppConstants.MOZ_MENU {
            self.menuButton.hidden = !self.toolbarIsShowing
        } else {
            self.bookmarkButton.hidden = !self.toolbarIsShowing
        }
        self.forwardButton.hidden = !self.toolbarIsShowing
        self.backButton.hidden = !self.toolbarIsShowing
        self.stopReloadButton.hidden = !self.toolbarIsShowing
        // Cliqz: Add tabs and new tab buttons to URLBar
        self.tabsButton.hidden = !self.toolbarIsShowing
        self.shareButton.hidden = !self.toolbarIsShowing
    }

    func transitionToOverlay(didCancel: Bool = false) {
        self.cancelButton.alpha = inOverlayMode ? 1 : 0
        self.progressBar.alpha = inOverlayMode || didCancel ? 0 : 1
        self.shareButton.alpha = inOverlayMode ? 0 : 1
        if AppConstants.MOZ_MENU {
            self.menuButton.alpha = inOverlayMode ? 0 : 1
        } else {
            self.bookmarkButton.alpha = inOverlayMode ? 0 : 1
        }
        self.forwardButton.alpha = inOverlayMode ? 0 : 1
        self.backButton.alpha = inOverlayMode ? 0 : 1
        self.stopReloadButton.alpha = inOverlayMode ? 0 : 1
        // Cliqz: Add tabs and new tab buttons to URLBar
        self.tabsButton.alpha = inOverlayMode ? 0 : 1
        
        let borderColor = inOverlayMode ? locationActiveBorderColor : locationBorderColor
        locationContainer.layer.borderColor = borderColor.CGColor

        if inOverlayMode {
            self.cancelButton.transform = CGAffineTransformIdentity
            // Cliqz: Commented out tabsButton transition as it will be always visible
//            let tabsButtonTransform = CGAffineTransformMakeTranslation(self.tabsButton.frame.width + URLBarViewUX.URLBarCurveOffset, 0)
//            self.tabsButton.transform = tabsButtonTransform
//            self.clonedTabsButton?.transform = tabsButtonTransform
//            self.rightBarConstraint?.updateOffset(URLBarViewUX.URLBarCurveOffset + URLBarViewUX.URLBarCurveBounceBuffer + tabsButton.frame.width)

            // Make the editable text field span the entire URL bar, covering the lock and reader icons.
            self.locationTextField?.snp_remakeConstraints { make in
                make.leading.equalTo(self.locationContainer).offset(URLBarViewUX.LocationContentOffset)
                make.top.bottom.trailing.equalTo(self.locationContainer)
            }
        } else {
            self.tabsButton.transform = CGAffineTransformIdentity
            // Cliqz: deleted cloned tabs button due to removing tabs button animation
//            self.clonedTabsButton?.transform = CGAffineTransformIdentity
            self.cancelButton.transform = CGAffineTransformMakeTranslation(self.cancelButton.frame.width, 0)
            self.rightBarConstraint?.updateOffset(defaultRightOffset)

            // Shrink the editable text field back to the size of the location view before hiding it.
            self.locationTextField?.snp_remakeConstraints { make in
                make.edges.equalTo(self.locationView.urlTextField)
            }
        }
    }

    func updateViewsForOverlayModeAndToolbarChanges() {
        self.cancelButton.hidden = !inOverlayMode
        self.progressBar.hidden = inOverlayMode
        if AppConstants.MOZ_MENU {
            self.menuButton.hidden = !self.toolbarIsShowing || inOverlayMode
        } else {
            self.bookmarkButton.hidden = !self.toolbarIsShowing || inOverlayMode
        }
        self.forwardButton.hidden = !self.toolbarIsShowing || inOverlayMode
        self.backButton.hidden = !self.toolbarIsShowing || inOverlayMode
        self.stopReloadButton.hidden = !self.toolbarIsShowing || inOverlayMode
        // Cliqz: Add tabs and new tab buttons to URLBar
        self.tabsButton.hidden = !self.toolbarIsShowing || inOverlayMode
    }

    func animateToOverlayState(overlayMode overlay: Bool, didCancel cancel: Bool = false) {
        prepareOverlayAnimation()
        layoutIfNeeded()

        inOverlayMode = overlay

        if !overlay {
            removeLocationTextField()
        }

        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: [], animations: { _ in
            self.transitionToOverlay(cancel)
            self.setNeedsUpdateConstraints()
            self.layoutIfNeeded()
        }, completion: { _ in
            self.updateViewsForOverlayModeAndToolbarChanges()
        })
    }

    func SELdidClickAddTab() {
        delegate?.urlBarDidPressTabs(self)
    }

    func SELdidClickCancel() {
        leaveOverlayMode(didCancel: true)
    }

    func SELtappedScrollToTopArea() {
        delegate?.urlBarDidPressScrollToTop(self)
    }

}

extension URLBarView: TabToolbarProtocol {
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
        if isLoading {
            stopReloadButton.setImage(helper?.ImageStop, forState: .Normal)
            stopReloadButton.setImage(helper?.ImageStopPressed, forState: .Highlighted)
        } else {
            stopReloadButton.setImage(helper?.ImageReload, forState: .Normal)
            stopReloadButton.setImage(helper?.ImageReloadPressed, forState: .Highlighted)
        }
    }

    func updatePageStatus(isWebPage isWebPage: Bool) {
        if !AppConstants.MOZ_MENU {
            bookmarkButton.enabled = isWebPage
        }
        stopReloadButton.enabled = isWebPage
        shareButton.enabled = isWebPage
    }

    override var accessibilityElements: [AnyObject]? {
        get {
            if inOverlayMode {
                guard let locationTextField = locationTextField else { return nil }
                return [locationTextField, cancelButton]
            } else {
                if toolbarIsShowing {
					// Cliqz: Removed stopReloadButton from the list as we don't use it anymore
                    return AppConstants.MOZ_MENU ? [backButton, forwardButton, stopReloadButton, locationView, shareButton, menuButton, tabsButton, progressBar] : [backButton, forwardButton,  locationView, shareButton, bookmarkButton, tabsButton, progressBar]
                } else {
                    return [locationView, tabsButton, progressBar]
                }
            }
        }
        set {
            super.accessibilityElements = newValue
        }
    }
}

extension URLBarView: TabLocationViewDelegate {
    func tabLocationViewDidLongPressReaderMode(tabLocationView: TabLocationView) -> Bool {
        return delegate?.urlBarDidLongPressReaderMode(self) ?? false
    }

    func tabLocationViewDidTapLocation(tabLocationView: TabLocationView) {
        let locationText = delegate?.urlBarDisplayTextForURL(locationView.url)
        enterOverlayMode(locationText, pasted: false)
    }

    func tabLocationViewDidLongPressLocation(tabLocationView: TabLocationView) {
        delegate?.urlBarDidLongPressLocation(self)
    }

    func tabLocationViewDidTapReload(tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressReload(self)
    }
    
    func tabLocationViewDidTapStop(tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressStop(self)
    }

    func tabLocationViewDidTapReaderMode(tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressReaderMode(self)
    }

    func tabLocationViewLocationAccessibilityActions(tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]? {
        return delegate?.urlBarLocationAccessibilityActions(self)
    }
}

extension URLBarView: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldReturn(autocompleteTextField: AutocompleteTextField) -> Bool {
        guard let text = locationTextField?.text else { return true }
        delegate?.urlBar(self, didSubmitText: text)
        return true
    }

    func autocompleteTextField(autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
        delegate?.urlBar(self, didEnterText: text)
        
        if let view = autocompleteTextField.inputAccessoryView as? QuerySuggestionView {
            view.didEnterText(text)
        }
    }

    func autocompleteTextFieldDidBeginEditing(autocompleteTextField: AutocompleteTextField) {
        autocompleteTextField.highlightAll()
    }

    func autocompleteTextFieldShouldClear(autocompleteTextField: AutocompleteTextField) -> Bool {
		delegate?.urlBarDidClearSearchField(self, oldText: autocompleteTextField.text)
        
        if let view = autocompleteTextField.inputAccessoryView as? QuerySuggestionView {
            view.didEnterText("")
        }
        return true
    }
}

// MARK: UIAppearance
extension URLBarView {
    dynamic var progressBarTint: UIColor? {
        get { return progressBar.progressTintColor }
        set { progressBar.progressTintColor = newValue }
    }

    dynamic var cancelTextColor: UIColor? {
        get { return cancelButton.titleColorForState(UIControlState.Normal) }
        set { return cancelButton.setTitleColor(newValue, forState: UIControlState.Normal) }
    }

    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }

}

extension URLBarView: Themeable {
    
    func applyTheme(themeName: String) {
        locationView.applyTheme(themeName)
        locationTextField?.applyTheme(themeName)

        guard let theme = URLBarViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        currentTheme = themeName
        locationBorderColor = theme.borderColor!
        locationActiveBorderColor = theme.activeBorderColor!
        progressBarTint = UIConstants.CliqzThemeColor
        cancelTextColor = theme.textColor
        actionButtonTintColor = theme.buttonTintColor
        // Cliqz: Set URLBar backgroundColor because of requirements
        backgroundColor = theme.backgroundColor
        // Cliqz: used regular button instead of TabsButton
        tabsButton.applyTheme(themeName)
    }
}
// Cliqz: override resignFirstResponder to dismiss the keyboard when it is called
extension URLBarView {
    override func resignFirstResponder() -> Bool {
        
        locationTextField?.enforceResignFirstResponder()
        return super.resignFirstResponder()
    }
}

extension URLBarView: AppStateDelegate {
    func appDidUpdateState(appState: AppState) {
        if toolbarIsShowing {
            let showShareButton = HomePageAccessors.isButtonInMenu(appState)
            homePageButton.hidden = showShareButton
            shareButton.hidden = !showShareButton
            homePageButton.enabled = HomePageAccessors.isButtonEnabled(appState)
        } else {
            homePageButton.hidden = true
            shareButton.hidden = true
        }
    }
}

/* Code for drawing the urlbar curve */
// Curve's aspect ratio
private let ASPECT_RATIO = 0.729

// Width multipliers
private let W_M1 = 0.343
private let W_M2 = 0.514
private let W_M3 = 0.49
private let W_M4 = 0.545
private let W_M5 = 0.723

// Height multipliers
private let H_M1 = 0.25
private let H_M2 = 0.5
private let H_M3 = 0.72
private let H_M4 = 0.961

/* Code for drawing the urlbar curve */
private class CurveView: UIView {
    private lazy var leftCurvePath: UIBezierPath = {
        var leftArc = UIBezierPath(arcCenter: CGPoint(x: 5, y: 5), radius: CGFloat(5), startAngle: CGFloat(-M_PI), endAngle: CGFloat(-M_PI_2), clockwise: true)
        leftArc.addLineToPoint(CGPoint(x: 0, y: 0))
        leftArc.addLineToPoint(CGPoint(x: 0, y: 5))
        leftArc.closePath()
        return leftArc
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        self.opaque = false
        self.contentMode = .Redraw
    }

    private func getWidthForHeight(height: Double) -> Double {
        return height * ASPECT_RATIO
    }

    private func drawFromTop(path: UIBezierPath) {
        let height: Double = Double(UIConstants.ToolbarHeight)
        let width = getWidthForHeight(height)
        let from = (Double(self.frame.width) - width * 2 - Double(URLBarViewUX.URLBarCurveOffset - URLBarViewUX.URLBarCurveBounceBuffer), Double(0))

        path.moveToPoint(CGPoint(x: from.0, y: from.1))
        path.addCurveToPoint(CGPoint(x: from.0 + width * W_M2, y: from.1 + height * H_M2),
              controlPoint1: CGPoint(x: from.0 + width * W_M1, y: from.1),
              controlPoint2: CGPoint(x: from.0 + width * W_M3, y: from.1 + height * H_M1))

        path.addCurveToPoint(CGPoint(x: from.0 + width,        y: from.1 + height),
              controlPoint1: CGPoint(x: from.0 + width * W_M4, y: from.1 + height * H_M3),
              controlPoint2: CGPoint(x: from.0 + width * W_M5, y: from.1 + height * H_M4))
    }

    private func getPath() -> UIBezierPath {
        let path = UIBezierPath()
        self.drawFromTop(path)
        path.addLineToPoint(CGPoint(x: self.frame.width, y: UIConstants.ToolbarHeight))
        path.addLineToPoint(CGPoint(x: self.frame.width, y: 0))
        path.addLineToPoint(CGPoint(x: 0, y: 0))
        path.closePath()
        return path
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context!)
        CGContextClearRect(context!, rect)
        CGContextSetFillColorWithColor(context!, URLBarViewUX.backgroundColorWithAlpha(1).CGColor)
		// Cliqz: Removed URLBar decorations according to requirements
/*
        getPath().fill()
        leftCurvePath.fill()
*/
        CGContextDrawPath(context!, CGPathDrawingMode.Fill)
        CGContextRestoreGState(context!)
    }
}

class ToolbarTextField: AutocompleteTextField {
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        // Cliqz: Changed TextField colors for forget mode theme
		theme.backgroundColor =  UIConstants.TextFieldBackgroundColor.colorWithAlphaComponent(1)
        theme.textColor = UIColor.blackColor()
        // Cliqz: changed the highlight color of the text field
        theme.highlightColor = AutocompleteTextFieldUX.HighlightColor //UIConstants.PrivateModeTextHighlightColor
        // Cliqz: Added Button tint color to Gray
        theme.buttonTintColor = UIColor.grayColor()

        themes[Theme.PrivateMode] = theme

        theme = Theme()
        // Cliqz: Changed TextField backgroundColor because of requirements
        theme.backgroundColor = UIConstants.TextFieldBackgroundColor.colorWithAlphaComponent(1)
        theme.textColor = UIColor.blackColor()
        theme.highlightColor = AutocompleteTextFieldUX.HighlightColor
		// Cliqz: Added Button tint color to Gray
		theme.buttonTintColor = UIColor.grayColor()

        themes[Theme.NormalMode] = theme

        return themes
    }()

    dynamic var clearButtonTintColor: UIColor? {
        didSet {
            // Clear previous tinted image that's cache and ask for a relayout
            tintedClearImage = nil
            setNeedsLayout()
        }
    }

    private var tintedClearImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Since we're unable to change the tint color of the clear image, we need to iterate through the
        // subviews, find the clear button, and tint it ourselves. Thanks to Mikael Hellman for the tip:
        // http://stackoverflow.com/questions/27944781/how-to-change-the-tint-color-of-the-clear-button-on-a-uitextfield
        for view in subviews as [UIView] {
            if let button = view as? UIButton {
                if let image = button.imageForState(.Normal) {
                    if tintedClearImage == nil {
                        tintedClearImage = tintImage(image, color: clearButtonTintColor)
                    }

                    if button.imageView?.image != tintedClearImage {
                        button.setImage(tintedClearImage, forState: .Normal)
                    }
                }
            }
        }
    }

    private func tintImage(image: UIImage, color: UIColor?) -> UIImage {
        guard let color = color else { return image }

        let size = image.size

        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        let context = UIGraphicsGetCurrentContext()
        image.drawAtPoint(CGPointZero, blendMode: CGBlendMode.Normal, alpha: 1.0)

        CGContextSetFillColorWithColor(context!, color.CGColor)
        CGContextSetBlendMode(context!, CGBlendMode.SourceIn)
        CGContextSetAlpha(context!, 1.0)

        let rect = CGRectMake(
            CGPointZero.x,
            CGPointZero.y,
            image.size.width,
            image.size.height)
        CGContextFillRect(UIGraphicsGetCurrentContext()!, rect)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImage!
    }
    
    // Cliqz: take the responsibility of dismissing keyboard of locationTextField to fix the sublinks problem by eliminating the race between resizing and click events
    func enforceResignFirstResponder () {
        super.resignFirstResponder();
    }
    
    override func resignFirstResponder() -> Bool {
        // override resignFirstResponder only in iPhone as doing that on iPad disables the hide button on the keyboard
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return false
        } else {
            return super.resignFirstResponder()
        }
    }
}

extension ToolbarTextField: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = ToolbarTextField.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        backgroundColor = theme.backgroundColor
        textColor = theme.textColor
        clearButtonTintColor = theme.buttonTintColor
        highlightColor = theme.highlightColor!
    }
}

extension URLBarView : QuerySuggestionDelegate {
    func autoComplete(suggestion: String) {
        self.locationTextField?.removeCompletion()
        self.locationTextField?.text = suggestion
    }
}
