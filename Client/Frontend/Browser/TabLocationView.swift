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
    func tabLocationViewDidTapLocation(tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(tabLocationView: TabLocationView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func tabLocationViewDidLongPressReaderMode(tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

struct TabLocationViewUX {
    static let HostFontColor = UIColor.blackColor()
	// Cliqz: Changed text color to black from grey for our styling
    static let BaseURLFontColor = UIColor.blackColor()
    static let BaseURLPitch = 0.75
    static let HostPitch = 1.0
    static let LocationContentInset = 8

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        // Cliqz: change the text colors for forget mode theme
        theme.URLFontColor = UIColor.whiteColor()
        theme.hostFontColor = UIColor.whiteColor()
        theme.backgroundColor = UIConstants.PrivateModeExpandBackgroundColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.URLFontColor = BaseURLFontColor
        theme.hostFontColor = HostFontColor
        theme.backgroundColor = UIColor.whiteColor()
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

    var url: NSURL? {
        didSet {
            let wasHidden = lockImageView.hidden
            lockImageView.hidden = url?.scheme != "https"
            if wasHidden != lockImageView.hidden {
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
                let wasHidden = readerModeButton.hidden
                self.readerModeButton.readerModeState = newReaderModeState
                readerModeButton.hidden = (newReaderModeState == ReaderModeState.Unavailable)
                if wasHidden != readerModeButton.hidden {
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                }
                UIView.animateWithDuration(0.1, animations: { () -> Void in
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

    lazy var placeholder: NSAttributedString = {
		// Cliqz: Changed Placeholder text and color according to requirements
//        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
		let placeholderText = NSLocalizedString("Search", tableName: "Cliqz", comment: "The text shown in the search field")
		return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor(rgb: 0x9B9B9B)])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        self.longPressRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.longPressRecognizer)
        self.tapRecognizer.delegate = self
        urlTextField.addGestureRecognizer(self.tapRecognizer)

        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(250, forAxis: UILayoutConstraintAxis.Horizontal)

        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont

        // Cliqz: Added left pading to the url text field
        urlTextField.setLeftPading(5)
        
        return urlTextField
    }()

    private lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = true
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = UIViewContentMode.Center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    private lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: #selector(TabLocationView.SELtapReaderModeButton), forControlEvents: .TouchUpInside)
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
        addSubview(lockImageView)
        addSubview(readerModeButton)

        lockImageView.snp_makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width + CGFloat(TabLocationViewUX.LocationContentInset * 2))
        }

        readerModeButton.snp_makeConstraints { make in
            make.trailing.centerY.equalTo(self)
            make.width.equalTo(self.readerModeButton.intrinsicContentSize().width + CGFloat(TabLocationViewUX.LocationContentInset * 2))
        }
    }

    override var accessibilityElements: [AnyObject]! {
        get {
            return [lockImageView, urlTextField, readerModeButton].filter { !$0.hidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        urlTextField.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)

            if lockImageView.hidden {
                make.leading.equalTo(self).offset(TabLocationViewUX.LocationContentInset)
            } else {
                make.leading.equalTo(self.lockImageView.snp_trailing)
            }

            if readerModeButton.hidden {
                make.trailing.equalTo(self).offset(-TabLocationViewUX.LocationContentInset)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp_leading)
            }
        }

        super.updateConstraints()
    }

    func SELtapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    func SELlongPressLocation(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    func SELtapLocation(recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    func SELreaderModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    private func updateTextWithURL() {
        if let httplessURL = url?.absoluteDisplayString(), let baseDomain = url?.baseDomain() {
            // Highlight the base domain of the current URL.
            let attributedString = NSMutableAttributedString(string: httplessURL)
            let nsRange = NSMakeRange(0, httplessURL.characters.count)

			attributedString.addAttribute(NSForegroundColorAttributeName, value: baseURLFontColor, range: nsRange)
			attributedString.colorSubstring(baseDomain, withColor: hostFontColor)
            attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(double: TabLocationViewUX.BaseURLPitch), range: nsRange)
            attributedString.pitchSubstring(baseDomain, withPitch: TabLocationViewUX.HostPitch)
            urlTextField.attributedText = attributedString
        } else {
            // If we're unable to highlight the domain, just use the URL as is.
            urlTextField.text = url?.absoluteString
        }
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail all other recognizers to avoid conflicts.
        return gestureRecognizer == longPressRecognizer
    }
}

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

extension TabLocationView: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = TabLocationViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        baseURLFontColor = theme.URLFontColor!
        hostFontColor = theme.hostFontColor!
        backgroundColor = theme.backgroundColor
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "reader_active.png"), forState: UIControlState.Selected)
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
                self.enabled = true
                self.selected = false
            case .Unavailable:
                self.enabled = false
                self.selected = false
            case .Active:
                self.enabled = true
                self.selected = true
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

    private override func canBecomeFirstResponder() -> Bool {
        return false
    }
}
