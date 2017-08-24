/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

protocol TabLocationViewDelegate {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
	// Cliqz: Changed text color to black from grey for our styling
    static let BaseURLFontColor = UIColor.black
    static let BaseURLPitch = 0.75
    static let HostPitch = 1.0
    static let LocationContentInset = 8
    // Cliqz: added constant for buttons width
    static let ButtonWidth = 25.0
    
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        // Cliqz: change the text colors for forget mode theme
        theme.URLFontColor = UIColor.white
        theme.hostFontColor = UIColor.white
        theme.backgroundColor = UIConstants.PrivateModeExpandBackgroundColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.URLFontColor = BaseURLFontColor
        theme.hostFontColor = HostFontColor
        theme.backgroundColor = UIColor.white
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!

    dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
        didSet { updateTextWithURL() }
	}

    dynamic var hostFontColor: UIColor = TabLocationViewUX.HostFontColor {
        didSet { updateTextWithURL() }
    }

    var url: URL? {
        didSet {
            let wasHidden = lockImageView.isHidden
            lockImageView.isHidden = url?.scheme != "https"
            if wasHidden != lockImageView.isHidden {
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            }
            updateTextWithURL()
            setNeedsUpdateConstraints()
        }
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                let wasHidden = readerModeButton.isHidden
                self.readerModeButton.readerModeState = newReaderModeState
                readerModeButton.isHidden = (newReaderModeState == ReaderModeState.Unavailable)
                if wasHidden != readerModeButton.isHidden {
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                }
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    if newReaderModeState == ReaderModeState.Unavailable {
                        self.readerModeButton.alpha = 0.0
                    } else {
                        self.readerModeButton.alpha = 1.0
                    }
                    self.setNeedsUpdateConstraints()
                    self.layoutIfNeeded()
                })
            }
        }
    }
    
    func hideReaderModeButton(hidden: Bool) {
        self.readerModeButton.isHidden = hidden
    }

    lazy var placeholder: NSAttributedString = {
		// Cliqz: Changed Placeholder text and color according to requirements
//        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
		let placeholderText = NSLocalizedString("Search", tableName: "Cliqz", comment: "The text shown in the search field")
		return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor(rgb: 0x9B9B9B)])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        // Cliqz: moved the guesture recognizers to the tabLocationView as the urlTextField does not take the whole view
        /*
        self.longPressRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.longPressRecognizer)
        self.tapRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.tapRecognizer)
        */
 
        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(250, for: UILayoutConstraintAxis.horizontal)

        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
		urlTextField.textAlignment = .left
        
        return urlTextField
    }()
    
    private var urlTextFieldWidth: CGFloat = 100.0

    fileprivate lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage.templateImageNamed("lock_verified.png"))
        lockImageView.isHidden = true
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = UIViewContentMode.center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    // Cliqz: added forget mode icon displayed on the far left side of the url bar in forget mode
    fileprivate lazy var forgetModeImageView: UIImageView = {
        let forgetModeImageView = UIImageView(image: UIImage(named: "forgetModeUrlBarIcon"))
        forgetModeImageView.isHidden = true
        forgetModeImageView.isAccessibilityElement = true
        forgetModeImageView.contentMode = UIViewContentMode.center
        forgetModeImageView.accessibilityLabel = NSLocalizedString("Forget Mode View", comment: "Accessibility label for the forget mode icon, which is only present if the current tab is in forget mode")
        return forgetModeImageView
    }()

    
    private lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: CGRect.zero)
        readerModeButton.isHidden = true
        readerModeButton.addTarget(self, action: #selector(TabLocationView.SELtapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TabLocationView.SELlongPressReaderModeButton(_:))))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: #selector(TabLocationView.SELreaderModeCustomAction))]
        return readerModeButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TabLocationView.SELlongPressLocation(_:)))
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TabLocationView.SELtapLocation(_:)))

        addSubview(urlTextField)
        addSubview(forgetModeImageView)
        addSubview(lockImageView)
        addSubview(readerModeButton)
        
        // Cliqz: added constaints for forget mode icon
        forgetModeImageView.snp_makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.equalTo(TabLocationViewUX.ButtonWidth)
        }
        
        urlTextField.snp_makeConstraints { make in
            make.top.bottom.equalTo(self)
            // Cliqz: changd the constraints of the urlTextField to make it centered
            make.centerX.equalTo(self)
            make.width.equalTo(self)
        }
        
        lockImageView.snp_makeConstraints { make in
            make.trailing.equalTo(urlTextField.snp_leading)
            make.centerY.equalTo(self)
            // Cliqz: changd the width constraint of the lockImageView
            make.width.equalTo(TabLocationViewUX.ButtonWidth)
        }
        
        readerModeButton.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(forgetModeImageView.snp_trailing)
            // Cliqz: changd the width constraint of the readerModeButton
            make.width.equalTo(TabLocationViewUX.ButtonWidth)
        }
        
        // Cliqz: moved the guesture recognizers to the tabLocationView as the urlTextField does not take the whole view
        self.longPressRecognizer.delegate = self
        self.addGestureRecognizer(self.longPressRecognizer)
        self.tapRecognizer.delegate = self
        self.addGestureRecognizer(self.tapRecognizer)

    }

    override var accessibilityElements: [Any]! {
        get {
            return [forgetModeImageView, lockImageView, urlTextField, readerModeButton].filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
		
        // Cliqz: update the constrains of the urlTextField & readerModeButton
//        urlTextField.snp_updateConstraints { make in
//            make.width.equalTo(urlTextFieldWidth)
//        }
		
        readerModeButton.snp_remakeConstraints { make in
            
            make.centerY.equalTo(self)
            make.width.equalTo(TabLocationViewUX.ButtonWidth)
            
            if forgetModeImageView.isHidden {
                make.leading.equalTo(self)
            } else {
                make.leading.equalTo(forgetModeImageView.snp_trailing)
            }
        }
        super.updateConstraints()
    }

    func SELtapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    func SELlongPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    func SELtapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    func SELreaderModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    private func updateTextWithURL() {
        
        /*
        if let httplessURL = url?.absoluteDisplayString(), let baseDomain = url?.baseDomain() {
            // Highlight the base domain of the current URL.
            let attributedString = NSMutableAttributedString(string: httplessURL)
            let nsRange = NSMakeRange(0, httplessURL.characters.count)

			attributedString.addAttribute(NSForegroundColorAttributeName, value: baseURLFontColor, range: nsRange)
			attributedString.colorSubstring(baseDomain, withColor: hostFontColor)
            attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: TabLocationViewUX.BaseURLPitch), range: nsRange)
            attributedString.pitchSubstring(baseDomain, withPitch: TabLocationViewUX.HostPitch)
            urlTextField.attributedText = attributedString
 
        } else {
            // If we're unable to highlight the domain, just use the URL as is.
            urlTextField.text = url?.absoluteString
        }
        */
        
        // Cliqz: disply only the domain name in the url TextField if possible
        let urlText = getDomainName(url)
        
        urlTextField.accessibilityLabel = url?.absoluteString
        urlTextField.accessibilityValue = url?.absoluteString
        
        if urlText.isEmpty {
            urlTextField.text = ""
            urlTextField.textAlignment = .left
            urlTextFieldWidth = getMaxUrlTextFieldWidth()
            return
        }
        
        let attributedString = NSMutableAttributedString(string: urlText)
        let nsRange = NSMakeRange(0, urlText.characters.count)
        
        attributedString.addAttribute(NSForegroundColorAttributeName, value: hostFontColor, range: nsRange)
        attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: TabLocationViewUX.HostPitch), range: nsRange)
        
        urlTextField.attributedText = attributedString
        urlTextField.textAlignment = .left
        urlTextFieldWidth = attributedString.size().width + 30
        
        let maxUrlTextFieldWidth = getMaxUrlTextFieldWidth()
        if urlTextFieldWidth > maxUrlTextFieldWidth {
            urlTextFieldWidth = maxUrlTextFieldWidth
        }
    }
    
    // Cliqz: get domain name of NSURL
    private func getDomainName(_ url: URL?) -> String {
        var domainName = ""
        if let baseDomain = url?.baseDomain() {
            domainName = baseDomain
        } else if let absoluteString = url?.absoluteString {
            domainName = absoluteString
        }
        return domainName
    }
    
    // Cliqz: added method to calculate the maximum width that the urlTextField can take
    private func getMaxUrlTextFieldWidth() -> CGFloat {
        var maxWidth: CGFloat = self.frame.width - 5
        
        // subtract the anti-tracking button width
        maxWidth -= CGFloat(URLBarViewUX.ButtonWidth)
        
        if !forgetModeImageView.isHidden {
            maxWidth -= forgetModeImageView.frame.width
        }
        if !lockImageView.isHidden {
            maxWidth -= lockImageView.frame.width
        }
        if !readerModeButton.isHidden {
            maxWidth -= readerModeButton.frame.width
        }
        
        return maxWidth
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail all other recognizers to avoid conflicts.
        return gestureRecognizer == longPressRecognizer
    }
}

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

extension TabLocationView: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = TabLocationViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        baseURLFontColor = theme.URLFontColor!
        hostFontColor = theme.hostFontColor!
        backgroundColor = theme.backgroundColor
        forgetModeImageView.isHidden = (themeName == Theme.NormalMode)
        lockImageView.tintColor = (themeName == Theme.NormalMode) ? UIConstants.NormalModeTextColor : UIConstants.PrivateModeTextColor
//        setNeedsUpdateConstraints()
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), for: UIControlState())
        setImage(UIImage(named: "reader_active.png"), for: UIControlState.selected)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var _readerModeState: ReaderModeState = ReaderModeState.Unavailable
    
    var readerModeState: ReaderModeState {
        get {
            return _readerModeState;
        }
        set (newReaderModeState) {
            _readerModeState = newReaderModeState
            switch _readerModeState {
            case .Available:
                self.isEnabled = true
                self.isSelected = false
            case .Unavailable:
                self.isEnabled = false
                self.isSelected = false
            case .Active:
                self.isEnabled = true
                self.isSelected = true
            }
        }
    }
}

private class DisplayTextField: UITextField {
    weak var accessibilityActionsSource: AccessibilityActionsSource?

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    fileprivate override var canBecomeFirstResponder : Bool {
        return false
    }
}
