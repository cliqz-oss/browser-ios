//
//  File.swift
//  Client
//
//  Created by Sahakyan on 8/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Shared
import XCGLogger

private let log = Logger.browserLogger

protocol CIURLBarActionDelegate: class {

	func urlBarDidPressTabs(_ urlBar: CIURLBar)
	func urlBarDidPressReaderMode(_ urlBar: CIURLBar)
	/// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
	func urlBarDidLongPressReaderMode(_ urlBar: CIURLBar) -> Bool
	func urlBarDidPressNewTab(_ urlBar: CIURLBar, button: UIButton)
	func urlBarDidPressAntitracking(_ urlBar: CIURLBar, trackersCount: Int, status: String)
	func urlBarDidLongPressLocation(_ urlBar: CIURLBar)
	func urlBarLocationAccessibilityActions(_ urlBar: CIURLBar) -> [UIAccessibilityCustomAction]?

}

protocol CIURLBarStateDelegate: class {

	func urlBarDidStartEditing(_ urlBar: CIURLBar)
	func urlBarDidFinishEditing(_ urlBar: CIURLBar)
	
	func urlBar(_ urlBar: CIURLBar, didEnterText text: String)
	func urlBar(_ urlBar: CIURLBar, didSubmitText text: String)
	
	func urlBarDidClearSearchField(_ urlBar: CIURLBar, oldText: String?)
}

protocol CIURLBarDataSource: class {

	func urlBarDisplayTextForURL(_ url: URL?) -> String?
}

struct CIURLBarUX {

	static let TextFieldPadding: CGFloat = 10
	static let TextFieldCornerRadius: CGFloat = 3
	static let TextFieldHeight = 28
	static let TextFieldTopOffset = 20

	static let ProgressTintColor = UIConstants.CliqzThemeColor

	static let URLBarButtonOffset: CGFloat = 5

	// TODO: Review themes
	static let Themes: [String: Theme] = {
		var themes = [String: Theme]()
		var theme = Theme()
		theme.backgroundColor = UIConstants.CliqzThemeColor
		theme.textColor = UIConstants.PrivateModeTextColor
		theme.tintColor = UIColor.white
		theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor

		themes[Theme.PrivateMode] = theme

		theme = Theme()
		theme.backgroundColor = UIConstants.CliqzThemeColor
		theme.textColor = UIConstants.NormalModeTextColor
		theme.tintColor = ProgressTintColor
		theme.buttonTintColor = UIColor.black

		themes[Theme.NormalMode] = theme 

		return themes
	}()

}

class CIURLBar: UIView {

	enum State {
		case expanded
		case collapsed
		case minimized
		case unknown
	}

	var state: State = .unknown {
		didSet {
			self.animateToState(state: state)
		}
	}

	var toolbarIsShowing = false {
		didSet {
			if state == .collapsed {
				self.backButton.isHidden = !toolbarIsShowing
				self.forwardButton.isHidden = !toolbarIsShowing
				self.bookmarkButton.isHidden = !toolbarIsShowing
				self.shareButton.isHidden = !toolbarIsShowing
				self.newTabButton.isHidden = !toolbarIsShowing
				self.tabsButton.isHidden = !toolbarIsShowing
				self.setNeedsUpdateConstraints()
			}
		}
	}

	weak var actionDelegate: CIURLBarActionDelegate?
	weak var stateDelegate: CIURLBarStateDelegate?
	weak var dataSource: CIURLBarDataSource?

	var theme: String = Theme.NormalMode

	lazy var locationTextField: ToolbarTextField! = {
		var textField = ToolbarTextField()
		
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.autocompleteDelegate = self
		textField.keyboardType = .webSearch
		textField.autocorrectionType = UITextAutocorrectionType.no
		textField.autocapitalizationType = UITextAutocapitalizationType.none
		textField.returnKeyType = UIReturnKeyType.go
		textField.enablesReturnKeyAutomatically = true
		textField.clearButtonMode = UITextFieldViewMode.always
		textField.font = UIConstants.DefaultChromeFont
		textField.accessibilityIdentifier = "address"
		textField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
		textField.attributedPlaceholder = self.locationView.placeholder
		self.locationContainer.addSubview(textField)

		let querySuggestionView = QuerySuggestionView.sharedInstance
		querySuggestionView.delegate = self
		textField.inputAccessoryView = querySuggestionView
		return textField
	}()

	lazy var locationView: TabLocationView = {
		let locationView = TabLocationView()
		locationView.readerModeState = ReaderModeState.Unavailable
		locationView.delegate = self
		return locationView
	}()
	
	lazy var locationContainer: UIView = {
		let locationContainer = UIView()
		locationContainer.translatesAutoresizingMaskIntoConstraints = false
		locationContainer.clipsToBounds = true
		locationContainer.layer.cornerRadius = CIURLBarUX.TextFieldCornerRadius
		
		return locationContainer
	}()
	
	fileprivate lazy var progressBar: UIProgressView = {
		let progressBar = UIProgressView()
		progressBar.progressTintColor = CIURLBarUX.ProgressTintColor
		progressBar.alpha = 0
		progressBar.isHidden = true
		return progressBar
	}()

	fileprivate lazy var collapseButton: UIButton! = {
		let button = InsetButton()
		button.alpha = 0
		button.isHidden = true
		button.setImage(UIImage.templateImageNamed("urlExpand"), for: .normal)
		button.addTarget(self, action: #selector(CIURLBar.SELdidClickCancel), for: UIControlEvents.touchUpInside)
		button.accessibilityLabel = "urlExpand"
		if let currentTheme = CIURLBarUX.Themes[self.theme] {
			button.setTitleColor(currentTheme.textColor, for: .normal)
		}
		self.locationContainer.addSubview(button)
		button.snp.makeConstraints { make in
			make.centerY.left.equalTo(self.locationContainer)
			make.size.equalTo(CGSize(width: 40, height: 40))
		}
		return button
	}()

	lazy var backButton: UIButton = { return UIButton() }()
	lazy var forwardButton: UIButton = { return UIButton() }()
	lazy var bookmarkButton: UIButton = { return UIButton() }()
	lazy var shareButton: UIButton = { return UIButton() }()

	fileprivate lazy var newTabButton: UIButton = {
		let button = UIButton(type: .custom)
//		button.setImage(UIImage.templateImageNamed("bottomNav-NewTab"), for: .normal)
		button.accessibilityLabel = NSLocalizedString("New tab", comment: "Accessibility label for the New tab button in the tab toolbar.")
		button.addTarget(self, action: #selector(CliqzURLBarView.SELdidClickNewTab), for: UIControlEvents.touchUpInside)
		return button
	}()
	lazy var tabsButton: CliqzTabsButton = { return CliqzTabsButton() }()

	var currentURL: URL? {
		get {
			return locationView.url as URL?
		}
		
		set(newURL) {
			if let url = newURL {
				if(url.host != currentURL?.host) {
					// TODO: Review if how to handle url change without notification
//					NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationRefreshAntiTrackingButton), object: nil, userInfo: ["newURL":url])
				}
			}
			self.currentQuery = nil
			locationView.url = newURL
		}
	}

	var currentQuery: String? {
		didSet {
			locationView.query = currentQuery
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

	func startEditing(_ initialText: String? = nil, pasted: Bool = false) {
//		createLocationTextField()
//		layoutIfNeeded()
		self.state = .expanded
		if pasted {
			self.locationTextField.text = ""
			DispatchQueue.main.async {
				self.locationTextField.text = initialText
			}
		} else {
			self.locationTextField?.text = initialText
		}
	}

	func endEditing() {
		self.state = .collapsed
	}

	func stopEditing() {
		self.currentQuery = self.locationTextField.text
		self.state = .collapsed
	}

	override func updateConstraints() {
		super.updateConstraints()
		StateGenerator.applyState(endStates: StateGenerator.generateStates(transitions: self.generateState(state: self.state)))
	}

	fileprivate func commonInit() {
		locationContainer.addSubview(locationView)
		addSubview(locationContainer)
		addSubview(progressBar)
		
		addSubview(backButton)
		addSubview(forwardButton)
		addSubview(bookmarkButton)
		addSubview(shareButton)
		addSubview(newTabButton)
		addSubview(tabsButton)

		setupConstraints()
	}

	private func setupConstraints() {
		self.state = .collapsed
		// TODO: move components with 2 states to the state generator
		StateGenerator.applyState(endStates: StateGenerator.generateStates(transitions: self.generateState(state: self.state)))

		self.locationView.snp.makeConstraints { make in
			make.top.right.bottom.equalTo(self.locationContainer)
			make.left.equalTo(self.locationContainer)
		}

		progressBar.snp.makeConstraints { make in
			make.top.equalTo(self.snp.bottom)
			make.width.equalTo(self)
		}

		backButton.snp.makeConstraints { make in
			make.centerY.equalTo(self)
			make.left.equalTo(self).offset(CIURLBarUX.URLBarButtonOffset)
			make.size.equalTo(UIConstants.ToolbarHeight)
		}
		
		forwardButton.snp.makeConstraints { make in
			make.left.equalTo(self.backButton.snp.right).offset(CIURLBarUX.URLBarButtonOffset)
			make.centerY.equalTo(self)
			make.size.equalTo(backButton)
		}

		shareButton.snp.makeConstraints { make in
			make.centerY.equalTo(self)
			make.size.equalTo(backButton)
		}

		bookmarkButton.snp.makeConstraints { make in
			make.left.equalTo(self.forwardButton.snp.right).offset(CIURLBarUX.URLBarButtonOffset)
			make.centerY.equalTo(self)
			make.size.equalTo(backButton)
		}

		tabsButton.snp.makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.right.equalTo(self).offset(-CIURLBarUX.URLBarButtonOffset)
			make.size.equalTo(UIConstants.ToolbarHeight)
		}

		newTabButton.snp.makeConstraints { make in
			make.right.equalTo(self.tabsButton.snp.left).offset(-CIURLBarUX.URLBarButtonOffset)
			make.centerY.equalTo(self)
			make.size.equalTo(backButton)
		}
	}

	@objc private func SELdidClickCancel() {
		self.currentQuery = ""
		self.state = .collapsed
	}
    
    func setAutocompleteSuggestion(_ suggestion: String?) {
        locationTextField?.setAutocompleteSuggestion(suggestion)
    }

}

extension CIURLBar {

	fileprivate func animateToState(state: State) {
		StateAnimator.animate(animators: generateAnimators(state: state))
	}
	
	private func generateAnimators(state: State) -> [Animator] {
		return StateAnimator.generateAnimators(state: generateState(state: state), parentView: self)
	}

	fileprivate func generateState(state: State) -> [Transition] {
		switch state {
		case .collapsed:
			return self.collapseLocationContainer() + self.collapseLocationTextField() + self.hideCollapseButton() +  self.showToolbarButtons()
		case .expanded:
			return self.showCollapseButton() + self.expandLocationTextField() + self.expandLocationContainer() + self.hideToolbarButtons()
		default:
			return []
		}
	}

	private func expandLocationContainer() -> [Transition] {
		let transition = Transition(endState: {
			self.locationContainer.snp.remakeConstraints({ make in
				make.trailing.leading.height.top.equalTo(self)
			})
			self.locationContainer.layer.cornerRadius = 0
		}, beforeTransition: {
			self.bringSubview(toFront: self.locationContainer)
			// TODO: move to applytheme
			self.locationContainer.backgroundColor = UIColor.white
		})
		return [transition]
	}

	private func collapseLocationContainer() -> [Transition] {
		let transition = Transition(endState: {
			self.locationContainer.snp.remakeConstraints({ make in
				if self.toolbarIsShowing {
					make.leading.equalTo(self.bookmarkButton.snp.trailing).offset(CIURLBarUX.URLBarButtonOffset)
					make.trailing.equalTo(self.shareButton.snp.leading).offset(-CIURLBarUX.URLBarButtonOffset)
				} else {
					make.leading.equalTo(self).offset(CIURLBarUX.TextFieldPadding)
					make.trailing.equalTo(self).offset(-CIURLBarUX.TextFieldPadding)
				}
				make.height.equalTo(CIURLBarUX.TextFieldHeight)
				make.top.equalTo(self).offset(CIURLBarUX.TextFieldTopOffset)
			})
			self.locationContainer.layer.cornerRadius = CIURLBarUX.TextFieldCornerRadius
		}, beforeTransition: {
			// TODO: move to applytheme
			self.applyTheme(self.theme)
		})
		return [transition]
	}
	
	private func expandLocationTextField() -> [Transition] {
		let transition = Transition(endState: {
			self.locationTextField.applyTheme(self.theme)
		}, beforeTransition: {
			self.locationTextField.snp.makeConstraints { make in
				make.top.right.bottom.equalTo(self.locationView)
				make.left.equalTo(self.locationView).offset(30)
			}
			self.layoutIfNeeded()
		}, afterTransition: {
			self.locationTextField.becomeFirstResponder()
		})
		return [transition]
	}

	private func collapseLocationTextField() -> [Transition] {
		let transition = Transition(endState: {
		}, beforeTransition: {
			self.locationTextField?.enforceResignFirstResponder()
			self.locationTextField?.removeFromSuperview()
			self.locationTextField = nil
		})
		return [transition]
	}

	private func showCollapseButton() -> [Transition] {
		let transition = Transition(endState: { 
			self.collapseButton?.alpha = 1
		}, beforeTransition: {
			self.collapseButton?.isHidden = false
			self.layoutIfNeeded()
		})
		return [transition]
	}

	private func hideCollapseButton() -> [Transition] {
		let transition = Transition(endState: {
			self.collapseButton?.alpha = 0
		}, afterTransition: {
			self.collapseButton?.removeFromSuperview()
			self.collapseButton = nil
		})
		return [transition]
	}

	private func showToolbarButtons() -> [Transition] {
		let transition = Transition(endState: {
			self.backButton.alpha = 1
			self.forwardButton.alpha = 1
			self.bookmarkButton.alpha = 1
			self.shareButton.alpha = 1
			self.newTabButton.alpha = 1
			self.tabsButton.alpha = 1
		}, beforeTransition: {
			self.backButton.isHidden = !self.toolbarIsShowing
			self.forwardButton.isHidden = !self.toolbarIsShowing
			self.bookmarkButton.isHidden = !self.toolbarIsShowing
			self.shareButton.isHidden = !self.toolbarIsShowing
			self.newTabButton.isHidden = !self.toolbarIsShowing
			self.tabsButton.isHidden = !self.toolbarIsShowing
		})
		return [transition]
	}

	private func hideToolbarButtons() -> [Transition] {
		let transition = Transition(endState: {
			self.backButton.alpha = 0
			self.forwardButton.alpha = 0
			self.bookmarkButton.alpha = 0
			self.shareButton.alpha = 0
			self.newTabButton.alpha = 0
			self.tabsButton.alpha = 0
		})
		return [transition]
	}
}

extension CIURLBar: Themeable {

	func applyTheme(_ themeName: String) {
		locationView.applyTheme(themeName)
		
		guard let newTheme = CIURLBarUX.Themes[themeName] else {
			log.error("Unable to apply unknown theme \(themeName)")
			return
		}
		self.theme = themeName
		if let _ = self.currentURL, self.currentQuery == nil {
			self.backgroundColor = newTheme.backgroundColor
		} else {
			self.backgroundColor = UIColor.clear
		}
		self.locationContainer.layer.borderColor = newTheme.borderColor?.cgColor
		// TODO: should be themable
		self.locationContainer.backgroundColor = UIColor.white
	}
}

extension CIURLBar: TabLocationViewDelegate {

	func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool {
		return self.actionDelegate?.urlBarDidLongPressReaderMode(self) ?? false
	}

	func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView) {
		self.actionDelegate?.urlBarDidPressReaderMode(self)
	}

	func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView) {
		let locationText = locationView.query != nil ? locationView.query! : self.dataSource?.urlBarDisplayTextForURL(locationView.url as URL?)
		self.startEditing(locationText)
	}
	
	func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView) {
		self.actionDelegate?.urlBarDidLongPressLocation(self)
	}

	func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]? {
		return self.actionDelegate?.urlBarLocationAccessibilityActions(self)
	}
}

extension CIURLBar: AutocompleteTextFieldDelegate {

	func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
		guard let text = locationTextField?.text else { return true }
		self.stateDelegate?.urlBar(self, didSubmitText: text)
		return true
	}
	
	func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
		self.stateDelegate?.urlBar(self, didEnterText: text)
		if let view = autocompleteTextField.inputAccessoryView as? QuerySuggestionView {
			view.updateCurrentQuery(text)
		}
	}
	
	func autocompleteTextFieldDidBeginEditing(_ autocompleteTextField: AutocompleteTextField) {
		autocompleteTextField.highlightAll()
	}
	
	func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool {
		self.stateDelegate?.urlBarDidClearSearchField(self, oldText: autocompleteTextField.text)
		if let view = autocompleteTextField.inputAccessoryView as? QuerySuggestionView {
			view.updateCurrentQuery("")
		}
		return true
	}
}

extension CIURLBar : QuerySuggestionDelegate {

	func autoComplete(_ suggestion: String) {
		self.locationTextField?.removeCompletion()
		self.locationTextField?.text = suggestion
	}
}
