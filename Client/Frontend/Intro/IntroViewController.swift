/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct IntroViewControllerUX {
    static let Width = 375
    static let Height = 667

    // Cliqz: replaced fixfox intro with cliqz intro
    static let CardSlides = ["cliqz-intro2", "cliqz-intro3"]
//    static let CardSlides = ["organize", "customize", "share", "choose", "sync"]

    static let NumberOfCards = CardSlides.count

    static let PagerCenterOffsetFromScrollViewBottom = 30

    static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let StartBrowsingButtonColor = UIColor(rgb: 0x363B40)
    static let StartBrowsingButtonHeight = 56

    static let SignInButtonTitle = NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let SignInButtonColor = UIColor(red: 0.259, green: 0.49, blue: 0.831, alpha: 1.0)
    static let SignInButtonHeight = 46
    static let SignInButtonCornerRadius = CGFloat(4)

    static let CardTextLineHeight = CGFloat(6)

    static let CardTitleOrganize = NSLocalizedString("Organize", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleCustomize = NSLocalizedString("Customize", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleShare = NSLocalizedString("Share", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleChoose = NSLocalizedString("Choose", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleSync = NSLocalizedString("Sync your Devices.", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")

    static let CardTextOrganize = NSLocalizedString("Easily switch between open pages with tabs.", tableName: "Intro", comment: "Description for the 'Organize' panel in the First Run tour.")
    static let CardTextCustomize = NSLocalizedString("Personalize your default search engine and more in Settings.", tableName: "Intro", comment: "Description for the 'Customize' panel in the First Run tour.")
    static let CardTextShare = NSLocalizedString("Use the share sheet to send links from other apps to Firefox.", tableName: "Intro", comment: "Description for the 'Share' panel in the First Run tour.")
    static let CardTextChoose = NSLocalizedString("Tap, hold and move the Firefox icon into your dock for easy access.", tableName: "Intro", comment: "Description for the 'Choose' panel in the First Run tour.")

    static let Card1ImageLabel = NSLocalizedString("The Show Tabs button is next to the Address and Search text field and displays the current number of open tabs.", tableName: "Intro", comment: "Accessibility label for the UI element used to display the number of open tabs, and open the tab tray.")
    static let Card2ImageLabel = NSLocalizedString("The Settings button is at the beginning of the Tabs Tray.", tableName: "Intro", comment: "Accessibility label for the Settings button in the tab tray.")
    static let Card3ImageLabel = NSLocalizedString("Firefox and the cloud", tableName: "Intro", comment: "Accessibility label for the image displayed in the 'Sync' panel of the First Run tour.")

    static let CardTextSyncOffsetFromCenter = 25
    static let Card3ButtonOffsetFromCenter = -10

    static let FadeDuration = 0.25

    static let BackForwardButtonEdgeInset = 20

    // Cliqz: changed the background colors
    static let Card1Color = UIColor(rgb: 0xFFFFFF)
    static let Card2Color = UIColor(rgb: 0x0096DD)
    static let Card3Color = UIColor(rgb: 0x0096DD)
    
    // Cliqz: new titles and texts for cards
    static let CardTitleCliqzBrowser = NSLocalizedString("The first browser with a built-in quick-search\nno detours, directly to the right destination.", tableName: "Cliqz", comment: "First card text in onBorading")
    
    static let CardTextTyping = NSLocalizedString("Simply start typing.\n\nYou immediately see the best result.\n\nSwipe to see more.", tableName: "Cliqz", comment: "Second card text in onBorading")
    
    static let CardTextLocationSearch = NSLocalizedString("When you share your location, you also get results for locations near you (Google Maps)", tableName: "Cliqz", comment: "Thrid card text in onBorading")
    
}

let IntroViewControllerSeenProfileKey = "IntroViewControllerSeen"

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish()
    func introViewControllerDidRequestToLogin(_ introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate {
    weak var delegate: IntroViewControllerDelegate?

    var slides = [UIImage]()
    var cards = [UIImageView]()
    var introViews = [UIView]()
    var titleLabels = [UILabel]()
    var textLabels = [UILabel]()

    var startBrowsingButton: UIButton!
    var introView: UIView?
    var slideContainer: UIView!
    var pageControl: UIPageControl!
    var backButton: UIButton!
    var forwardButton: UIButton!
    var signInButton: UIButton!
    
    // Cliqz: added attribute to calculate the duration user take on each page
    var durationStartTime : Double?
    // Cliqz: added keep track of current page index to detect whether user swipe left or right
    var currentPageIndex = 0
    
    
    // Cliqz: custom getting started button
    lazy var gettingStartedButton: UIButton = self.createGettingStartedButton()
    
    fileprivate func createGettingStartedButton() -> UIButton {
        let button = UIButton()
        let buttonTitle = NSLocalizedString("Let's start!", tableName: "Cliqz", comment: "Start buttun title for onBorading")
        button.setTitle(buttonTitle, for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold)
        button.setBackgroundImage(UIImage(named: "getting-started"), for: UIControlState())
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.addTarget(self, action: #selector(IntroViewController.SELstartBrowsing), for: UIControlEvents.touchUpInside)
        button.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(200.0)
            make.height.equalTo(40.0)
        }

        return button
    }

    fileprivate var scrollView: IntroOverlayScrollView!

    var slideVerticalScaleFactor: CGFloat = 1.0

    override func viewDidLoad() {
        view.backgroundColor = UIColor.white

        // scale the slides down for iPhone 4S
        if view.frame.height <=  480 {
            slideVerticalScaleFactor = 1.33
        }

        for slideName in IntroViewControllerUX.CardSlides {
            slides.append(UIImage(named: slideName)!)
        }

        // Cliqz: Commented start browsing button
    /*
        startBrowsingButton = UIButton()
        startBrowsingButton.backgroundColor = IntroViewControllerUX.StartBrowsingButtonColor
        startBrowsingButton.setTitle(IntroViewControllerUX.StartBrowsingButtonTitle, forState: UIControlState.Normal)
        startBrowsingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startBrowsingButton.addTarget(self, action: #selector(IntroViewController.SELstartBrowsing), forControlEvents: UIControlEvents.TouchUpInside)
        startBrowsingButton.accessibilityIdentifier = "IntroViewController.startBrowsingButton"

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp_makeConstraints { (make) -> Void in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(IntroViewControllerUX.StartBrowsingButtonHeight)
        }
     */

        scrollView = IntroOverlayScrollView()
        scrollView.backgroundColor = UIColor.clear
        scrollView.accessibilityLabel = NSLocalizedString("Intro Tour Carousel", comment: "Accessibility label for the introduction tour carousel")
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        view.addSubview(scrollView)

        slideContainer = UIView()
        slideContainer.backgroundColor = IntroViewControllerUX.Card1Color
        for i in 0..<IntroViewControllerUX.NumberOfCards {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = slides[i]
            slideContainer.addSubview(imageView)
        }

        scrollView.addSubview(slideContainer)
        scrollView.snp_makeConstraints { (make) -> Void in
            // Cliqz: remove start browsing button
            make.left.right.top.bottom.equalTo(self.view)
//            make.left.right.top.equalTo(self.view)
//            make.bottom.equalTo(startBrowsingButton.snp_top)
        }

        // Cliqz: Used custom page control to be able to change the indicator images
        pageControl = CustomPageControl(activeImage: UIImage(named: "page-control-active")!, inactiveImage: UIImage(named: "page-control-inactive")!)
        
//        pageControl = UIPageControl()
//        pageControl.pageIndicatorTintColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
//        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.numberOfPages = IntroViewControllerUX.NumberOfCards
        pageControl.accessibilityIdentifier = "pageControl"
        pageControl.addTarget(self, action: #selector(IntroViewController.changePage), for: UIControlEvents.valueChanged)

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            // Cliqz: remove start browsing button
            make.centerY.equalTo(self.view.snp_bottom).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
//            make.centerY.equalTo(self.startBrowsingButton.snp_top).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
        }


        func addCard(_ text: String, title: String) {
            let introView = UIView()
            self.introViews.append(introView)
            self.addLabelsToIntroView(introView, text: text, title: title)
        }


        // Cliqz: changed titles and texts of the cards
        addTextCard(IntroViewControllerUX.CardTextTyping)
        addTextCard(IntroViewControllerUX.CardTextLocationSearch, additionalView: gettingStartedButton)
            
        /*
        addCard(IntroViewControllerUX.CardTextOrganize, title: IntroViewControllerUX.CardTitleOrganize)
        addCard(IntroViewControllerUX.CardTextCustomize, title: IntroViewControllerUX.CardTitleCustomize)
        addCard(IntroViewControllerUX.CardTextShare, title: IntroViewControllerUX.CardTitleShare)
        addCard(IntroViewControllerUX.CardTextChoose, title: IntroViewControllerUX.CardTitleChoose)
        */


        // Cliqz: removed Sync card
        /*
        // Sync card, with sign in to sync button.

        signInButton = UIButton()
        signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
        signInButton.setTitle(IntroViewControllerUX.SignInButtonTitle, forState: .Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.layer.cornerRadius = IntroViewControllerUX.SignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: #selector(IntroViewController.SELlogin), forControlEvents: UIControlEvents.TouchUpInside)
        signInButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(IntroViewControllerUX.SignInButtonHeight)
        }

        let syncCardView =  UIView()
        addViewsToIntroView(syncCardView, view: signInButton, title: IntroViewControllerUX.CardTitleSync)
        introViews.append(syncCardView)
        */
        
        // Add all the cards to the view, make them invisible with zero alpha

        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.slideContainer.snp_bottom)
                // Cliqz: remove start browsing button
                make.bottom.equalTo(self.view.snp_bottom)
//                make.bottom.equalTo(self.startBrowsingButton.snp_top)
                make.left.right.equalTo(self.view)
            }
        }

        // Make whole screen scrollable by bringing the scrollview to the top
        view.bringSubview(toFront: scrollView)
        view.bringSubview(toFront: pageControl)


        // Activate the first card
        setActiveIntroView(introViews[0], forPage: 0)

        setupDynamicFonts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(IntroViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func SELDynamicFontChanged(_ notification: Notification) {
        guard notification.name == NotificationDynamicFontChanged else { return }
        setupDynamicFonts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.snp_remakeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            // Cliqz: remove start browsing button
            make.bottom.equalTo(self.view.snp_bottom)
//            make.bottom.equalTo(self.startBrowsingButton.snp_top)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            if let imageView = slideContainer.subviews[i] as? UIImageView {
                imageView.frame = CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide)
                imageView.contentMode = UIViewContentMode.scaleAspectFit
            }
        }
        slideContainer.frame = CGRect(x: 0, y: 0, width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        scrollView.contentSize = CGSize(width: slideContainer.frame.width, height: slideContainer.frame.height)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    override var shouldAutorotate : Bool {
        return false
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return UIInterfaceOrientationMask.portrait
    }

    func SELstartBrowsing() {
        self.dismiss(animated: true, completion: nil)
        delegate?.introViewControllerDidFinish()
        // Cliqz: logged Onboarding event
        if let startTime = durationStartTime {
            let duration = Int(Date.getCurrentMillis() - startTime)
            TelemetryLogger.sharedInstance.logEvent(.Onboarding("click", pageControl.currentPage, duration))
            durationStartTime = nil
        }
    }

    func SELback() {
        if introView == introViews[1] {
            setActiveIntroView(introViews[0], forPage: 0)
            scrollView.scrollRectToVisible(scrollView.subviews[0].frame, animated: true)
            pageControl.currentPage = 0
        } else if introView == introViews[2] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        }
    }

    func SELforward() {
        if introView == introViews[0] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        } else if introView == introViews[1] {
            setActiveIntroView(introViews[2], forPage: 2)
            scrollView.scrollRectToVisible(scrollView.subviews[2].frame, animated: true)
            pageControl.currentPage = 2
        }
    }

    func SELlogin() {
		delegate?.introViewControllerDidRequestToLogin(self)
    }

    fileprivate var accessibilityScrollStatus: String {
		return String(format: NSLocalizedString("Introductory slide %@ of %@", tableName: "Intro", comment: "String spoken by assistive technology (like VoiceOver) stating on which page of the intro wizard we currently are. E.g. Introductory slide 1 of 3"), NumberFormatter.localizedString(from: NSNumber(value: pageControl.currentPage+1), number: .decimal), NumberFormatter.localizedString(from: NSNumber(value: IntroViewControllerUX.NumberOfCards), number: .decimal))
    }

    func changePage() {
        let swipeCoordinate = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: swipeCoordinate, y: 0), animated: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Need to add this method so that when forcibly dragging, instead of letting deceleration happen, should also calculate what card it's on.
        // This especially affects sliding to the last or first slides.
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Need to add this method so that tapping the pageControl will also change the card texts.
        // scrollViewDidEndDecelerating waits until the end of the animation to calculate what card it's on.
        scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        // Cliqz: log swipe telemetry singal for onboarding
        logSwipeTelemetrySingal(currentPageIndex, newPageIndex: page)
        setActiveIntroView(introViews[page], forPage: page)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumHorizontalOffset = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset = scrollView.contentOffset.x

        var percentage = currentHorizontalOffset / maximumHorizontalOffset
        var startColor: UIColor, endColor: UIColor

        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page

        if(percentage < 0.5) {
            startColor = IntroViewControllerUX.Card1Color
            endColor = IntroViewControllerUX.Card2Color
            percentage = percentage * 2
        } else {
            startColor = IntroViewControllerUX.Card2Color
            endColor = IntroViewControllerUX.Card3Color
            percentage = (percentage - 0.5) * 2
        }
        // Cliqz: disabled changing container coder gradually while navigating between cards
//        slideContainer.backgroundColor = colorForPercentage(percentage, start: startColor, end: endColor)
    }

    fileprivate func colorForPercentage(_ percentage: CGFloat, start: UIColor, end: UIColor) -> UIColor {
        let s = start.components
        let e = end.components
        let newRed   = (1.0 - percentage) * s.red   + percentage * e.red
        let newGreen = (1.0 - percentage) * s.green + percentage * e.green
        let newBlue  = (1.0 - percentage) * s.blue  + percentage * e.blue
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

    fileprivate func setActiveIntroView(_ newIntroView: UIView, forPage page: Int) {
        if introView != newIntroView {
            // Cliqz: set the current page index
            currentPageIndex = page
            // Cliqz: removed the fade animation when switching between cards
            self.introView?.alpha = 0
            self.introView = newIntroView
            newIntroView.alpha = 1.0
            if page == (IntroViewControllerUX.NumberOfCards - 1) {
                // Cliqz: replaced signinButton with gettingStarted button in the last card
                self.scrollView.signinButton = self.gettingStartedButton
            } else {
                self.scrollView.signinButton = nil
            }
            
//            UIView.animateWithDuration(IntroViewControllerUX.FadeDuration, animations: { () -> Void in
//                self.introView?.alpha = 0
//                self.introView = newIntroView
//                newIntroView.alpha = 1.0
//            }, completion: { _ in
//                if page == (IntroViewControllerUX.NumberOfCards - 1) {
//                    self.scrollView.signinButton = self.signInButton
//                } else {
//                    self.scrollView.signinButton = nil
//                }
//            })
            // Cliqz: logged Onboarding event
            TelemetryLogger.sharedInstance.logEvent(.Onboarding("show", page, nil))
            durationStartTime = Date.getCurrentMillis()
        }
		if page == pageControl.numberOfPages - 1 {
			LocationManager.sharedInstance.askForLocationAccess()
		}
    }

    fileprivate var scaledWidthOfSlide: CGFloat {
        return view.frame.width
    }

    fileprivate var scaledHeightOfSlide: CGFloat {
        return (view.frame.width / slides[0].size.width) * slides[0].size.height / slideVerticalScaleFactor
    }

    fileprivate func attributedStringForLabel(_ text: String) -> NSMutableAttributedString {
        // Cliqz: modified the styling for the text label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(5)
        let textAttributes = [
            NSForegroundColorAttributeName  : UIColor.white,
            NSParagraphStyleAttributeName   : paragraphStyle]
        let string = NSMutableAttributedString(string: text, attributes: textAttributes)

//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = IntroViewControllerUX.CardTextLineHeight
//        paragraphStyle.alignment = .Center
//
//        let string = NSMutableAttributedString(string: text)
//        string.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, string.length))
        
        return string
    }

    fileprivate func addLabelsToIntroView(_ introView: UIView, text: String, title: String = "") {
        let label = UILabel()

        label.numberOfLines = 0
        label.attributedText = attributedStringForLabel(text)
        textLabels.append(label)

        addViewsToIntroView(introView, view: label, title: title)
    }

    fileprivate func addViewsToIntroView(_ introView: UIView, view: UIView, title: String = "") {
        introView.addSubview(view)
        view.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView)
            make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
        }

        if !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = NSTextAlignment.center
            // Cliqz: modified the styling for the title label
            titleLabel.attributedText = attributedStringForTitle(title)
//            titleLabel.text = title
//            titleLabels.append(titleLabel)
            introView.addSubview(titleLabel)
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(introView)
                make.bottom.equalTo(view.snp_top)
                make.centerX.equalTo(introView)
                make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
            }
        }

    }
    
    // Cliqz: Added method to modify the styling for the text label
    fileprivate func attributedStringForTitle(_ text: String) -> NSMutableAttributedString {
        let string = NSMutableAttributedString(string: text)
        var fontAdjustment = 0
        if (self.view.frame.width > 320) {
            fontAdjustment = 3
        }
        
        // Add first lines styling
        let firstLineLength = text.components(separatedBy: "\n")[0].characters.count
        string.addAttributes([NSFontAttributeName: UIFont(name: "Lato-Medium", size: CGFloat(14+fontAdjustment))!], range: NSMakeRange(0, firstLineLength))
        
        // Add second lines styling
        let secondLineLength = string.length - firstLineLength
        string.addAttributes([NSFontAttributeName: UIFont(name: "Lato-Light", size: CGFloat(12+fontAdjustment))!], range: NSMakeRange(firstLineLength, secondLineLength))
        
        return string;
    }
    
    // Cliqz: Added method to create custom page with text and an optional view
    func addTextCard(_ text: String, additionalView: UIView? = nil) {
        let introView =  UIView()
        addViewsToIntroView(introView, text: text, additionalView: additionalView)
        introViews.append(introView)
    }
    
    fileprivate func addViewsToIntroView(_ introView: UIView, text: String, additionalView: UIView?) {
        introView.backgroundColor = UIColor(rgb: 0x262626)
        
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.attributedText = attributedStringForLabel(text)
        if (self.view.frame.width > 320) {
            textLabel.font = UIFont(name: "Lato-Medium", size: 18)
        } else {
            textLabel.font = UIFont(name: "Lato-Medium", size: 16)
        }
        
        
        introView.addSubview(textLabel)
        textLabel.snp_makeConstraints { (make) -> Void in
            make.topMargin.equalTo(30)
            make.centerX.equalTo(introView)
            make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
        }
        
        if let view = additionalView {
            introView.addSubview(view)
            view.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(textLabel.snp_bottom).offset(self.view.frame.width > 320 ? 50 : 20)
                make.centerX.equalTo(introView)
            }
        }
        
    }
    fileprivate func setupDynamicFonts() {
        // Cliqz: Commented start browsing button font setting
//        startBrowsingButton.titleLabel?.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroBigFontSize)
        // Cliqz: Commented sing in button font setting
//        signInButton.titleLabel?.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroStandardFontSize, weight: UIFontWeightMedium)
        
        for titleLabel in titleLabels {
            titleLabel.font = UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.IntroBigFontSize, weight: UIFontWeightBold)
        }
        
        for label in textLabels {
            label.font = UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        }
    }
    
    // Cliqz: added method to log swipe telemetry signals
    func logSwipeTelemetrySingal(_ currentPageIndex: Int, newPageIndex: Int) {
        guard currentPageIndex != newPageIndex else {
            return
        }
        if let startTime = durationStartTime {
            let duration = Int(Date.getCurrentMillis() - startTime)
            var action: String = ""
            if newPageIndex > currentPageIndex {
                action = "swipe_left"
            } else {
                action = "swipe_right"
            }
            TelemetryLogger.sharedInstance.logEvent(.Onboarding(action, newPageIndex, duration))
            durationStartTime = nil
        }
    }
}

fileprivate class IntroOverlayScrollView: UIScrollView {
    weak var signinButton: UIButton?

    fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let signinFrame = signinButton?.frame {
            let convertedFrame = convert(signinFrame, from: signinButton?.superview)
            if convertedFrame.contains(point) {
                return false
            }
        }

        return CGRect(origin: self.frame.origin, size: CGSize(width: self.contentSize.width, height: self.frame.size.height)).contains(point)
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
}
