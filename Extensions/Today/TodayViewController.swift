/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit

private let log = Logger.browserLogger

struct TodayUX {
    // Cliqz: changed privateBrowsingColor to white
    static let privateBrowsingColor = UIColor.white //UIColor(colorString: "CE6EFC")
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)

    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0

    static let copyLinkButtonHeight: CGFloat = 44

    static let verticalWidgetMargin: CGFloat = 10
    static let horizontalWidgetMargin: CGFloat = 10
    static var defaultWidgetTextMargin: CGFloat = 22

    static let buttonSpacerMultipleOfScreen = 0.4
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    fileprivate lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .touchUpInside)
		//Cliqz: Changed the localization string
        imageButton.labelText = NSLocalizedString("New Tab", tableName: "Cliqz", comment: "Widget item for a new tab")

        let button = imageButton.button
        button.setImage(UIImage(named: "new_tab_button_normal"), for: UIControlState())
#if !CLIQZ
        button.setImage(UIImage(named: "new_tab_button_highlight"), for: .highlighted)
#endif
        let label = imageButton.label
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: TodayUX.imageButtonTextSize)

        imageButton.sizeToFit()
        return imageButton
    }()

    fileprivate lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .touchUpInside)
		// Cliqz: Changed Button title to ours
		imageButton.labelText = NSLocalizedString("New Private Tab", tableName: "Cliqz", comment: "New private tab title")

        let button = imageButton.button
        button.setImage(UIImage(named: "new_private_tab_button_normal"), for: UIControlState())
#if !CLIQZ
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), for: .highlighted)
#endif
        let label = imageButton.label
        label.textColor = TodayUX.privateBrowsingColor
        label.font = UIFont.systemFont(ofSize: TodayUX.imageButtonTextSize)

        return imageButton
    }()

    fileprivate lazy var openCopiedLinkButton: ButtonWithSublabel = {
        let button = ButtonWithSublabel()
        button.setTitle(NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", tableName: "Today", value: "Go to copied link", comment: "Go to link on clipboard"), for: UIControlState())
        button.addTarget(self, action: #selector(onPressOpenClibpoard), for: .touchUpInside)

        // We need to set the background image/color for .Normal, so the whole button is tappable.
        button.setBackgroundColor(UIColor.clear, forState: UIControlState())
        button.setBackgroundColor(TodayUX.backgroundHightlightColor, forState: .highlighted)
        button.setImage(UIImage(named: "copy_link_icon"), for: UIControlState())

        button.label.font = UIFont.systemFont(ofSize: TodayUX.labelTextSize)
        button.subtitleLabel.font = UIFont.systemFont(ofSize: TodayUX.linkTextSize)

        return button
    }()

    fileprivate lazy var buttonSpacer: UIView = UIView()

    fileprivate var copiedURL: URL? {
        if let string = UIPasteboard.general.string,
            let url = URL(string: string), url.isWebPage() {
            return url
        } else {
            return nil
        }
    }

    fileprivate var hasCopiedURL: Bool {
        return copiedURL != nil
    }

    fileprivate var scheme: String {
        
#if CLIQZ
        // Cliqz: return correct scheme so that today's widget redirect to Cliqz app not firefox app
        return "cliqz"
#else
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(buttonSpacer)

        // New tab button and label.
		// Cliqz: Updated constraints to center the buttons
        view.addSubview(newTabButton)
        newTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(buttonSpacer).offset(5)
            make.centerX.equalTo(buttonSpacer.snp_left).offset(-6)
        }

        // New private tab button and label.
        view.addSubview(newPrivateTabButton)
        newPrivateTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(newTabButton.snp_centerY)
            make.centerX.equalTo(buttonSpacer.snp_right)
        }

        newTabButton.label.snp_makeConstraints { make in
            make.leading.greaterThanOrEqualTo(view)
        }

        newPrivateTabButton.label.snp_makeConstraints { make in
            make.trailing.lessThanOrEqualTo(view)
            make.left.greaterThanOrEqualTo(newTabButton.label.snp_right).priorityHigh()
        }

        buttonSpacer.snp_makeConstraints { make in
            make.width.equalTo(view.snp_width).multipliedBy(TodayUX.buttonSpacerMultipleOfScreen)
            make.centerX.equalTo(view.snp_centerX)
            make.top.equalTo(view.snp_top).offset(TodayUX.verticalWidgetMargin)
            make.bottom.equalTo(newPrivateTabButton.label.snp_bottom).priorityLow()
        }

        view.addSubview(openCopiedLinkButton)

        openCopiedLinkButton.snp_makeConstraints { make in
            make.top.equalTo(buttonSpacer.snp_bottom).offset(TodayUX.verticalWidgetMargin)
            make.width.equalTo(view.snp_width)
            make.centerX.equalTo(view.snp_centerX)
            make.height.equalTo(TodayUX.copyLinkButtonHeight)
        }

        view.snp_remakeConstraints { make in
            var extraHeight = TodayUX.verticalWidgetMargin
            if hasCopiedURL {
                extraHeight += TodayUX.copyLinkButtonHeight + TodayUX.verticalWidgetMargin
            }
            make.height.equalTo(buttonSpacer.snp_height).offset(extraHeight).priorityHigh()
        }
        
        #if CLIQZ
			// Cliqz: Hide private tab option from today's widget
			openCopiedLinkButton.isHidden = true
        #endif
    }

    override func viewDidLayoutSubviews() {
        let preferredWidth: CGFloat = view.frame.size.width / CGFloat(buttonSpacer.subviews.count + 1)
        newPrivateTabButton.label.preferredMaxLayoutWidth = preferredWidth
        newTabButton.label.preferredMaxLayoutWidth = preferredWidth
    }

    func updateCopiedLink() {
        if let url = self.copiedURL {
            self.openCopiedLinkButton.isHidden = false
            self.openCopiedLinkButton.subtitleLabel.isHidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteString
            self.openCopiedLinkButton.remakeConstraints()
        } else {
            self.openCopiedLinkButton.isHidden = true
        }

        self.view.setNeedsLayout()
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        TodayUX.defaultWidgetTextMargin = defaultMarginInsets.left
        return UIEdgeInsetsMake(0, 0, TodayUX.verticalWidgetMargin, 0)
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        DispatchQueue.main.async {
            // updates need to be made on the main thread
#if !CLIQZ
            self.updateCopiedLink()
#endif
            // and we need to call the completion handler in every branch.
            completionHandler(NCUpdateResult.newData)
        }
        completionHandler(NCUpdateResult.newData)
    }

    // MARK: Button behaviour

    @objc func onPressNewTab(_ view: UIView) {
        openContainingApp("")
    }

    @objc func onPressNewPrivateTab(_ view: UIView) {
        openContainingApp("?private=true")
    }

    fileprivate func openContainingApp(_ urlSuffix: String = "") {
        let urlString = "\(scheme)://\(urlSuffix)"
        self.extensionContext?.open(URL(string: urlString)!) { success in
//            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(_ view: UIView) {
        if let urlString = UIPasteboard.general.string,
            let _ = URL(string: urlString) {
            let encodedString =
                urlString.escape()
            openContainingApp("?url=\(encodedString)")
        }
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        colorView.backgroundColor = color

        UIGraphicsBeginImageContext(colorView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            colorView.layer.render(in: context)
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, for: state)
    }
}

class ImageButtonWithLabel: UIView {

    lazy var button = UIButton()

    lazy var label = UILabel()

    var labelText: String? {
        set {
            label.text = newValue
            label.sizeToFit()
        }
        get {
            return label.text
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: CGRect.zero)
        performLayout()
    }

    func performLayout() {
        addSubview(button)
        addSubview(label)

        button.snp_makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.centerX.equalTo(self)
        }

        snp_makeConstraints { make in
            make.width.equalTo(button)
            make.height.equalTo(button)
        }

        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center

        label.snp_makeConstraints { make in
            make.centerX.equalTo(button.snp_centerX)
            make.top.equalTo(button.snp_bottom).offset(TodayUX.verticalWidgetMargin / 2)
        }
    }

    func addTarget(_ target: AnyObject?, action: Selector, forControlEvents events: UIControlEvents) {
        button.addTarget(target, action: action, for: events)
    }
}

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel: UILabel = UILabel()

    lazy var label: UILabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    fileprivate func performLayout() {
        self.snp_removeConstraints()

        let titleLabel = self.label
        titleLabel.textColor = UIColor.white

        self.titleLabel?.removeFromSuperview()
        addSubview(titleLabel)

        let imageView = self.imageView!

        let subtitleLabel = self.subtitleLabel
        subtitleLabel.textColor = UIColor.white
        self.addSubview(subtitleLabel)

        imageView.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.right.equalTo(titleLabel.snp_left).offset(-TodayUX.horizontalWidgetMargin)
        }

        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.snp_makeConstraints { make in
            make.left.equalTo(titleLabel.snp_left)
            make.top.equalTo(titleLabel.snp_bottom).offset(TodayUX.verticalWidgetMargin / 2)
            make.right.lessThanOrEqualTo(self.snp_right).offset(-TodayUX.horizontalWidgetMargin)
        }

        remakeConstraints()
    }

    func remakeConstraints() {
        self.label.snp_remakeConstraints { make in
            make.top.equalTo(self.snp_top).offset(TodayUX.verticalWidgetMargin / 2)
            make.left.equalTo(self.snp_left).offset(TodayUX.defaultWidgetTextMargin).priorityHigh()
        }
    }

    override func setTitle(_ text: String?, for state: UIControlState) {
        self.label.text = text
        super.setTitle(text, for: state)
    }
}
