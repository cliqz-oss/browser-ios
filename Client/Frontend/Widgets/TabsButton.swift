/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

struct TabsButtonUX {
    static let TitleColor: UIColor = UIColor.blackColor()
    static let TitleBackgroundColor: UIColor = UIColor.whiteColor()
    static let CornerRadius: CGFloat = 2
    // Cliqz: change the the title font of TabsButton
    static let TitleFont: UIFont = UIFont.boldSystemFontOfSize(10) //UIFont.boldSystemFontOfSize
    static let BorderStrokeWidth: CGFloat = 1

    static let BorderColor: UIColor = UIColor.clearColor()
	// Cliqz: Changed Insets to make Tabs button as big as UITextField
    static let TitleInsets = UIEdgeInsets(top: 11, left: 8, bottom: 5, right: 11)
    // UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModePurple

		// Cliqz: Removed Border in Private Mode
        theme.borderWidth = 0 // BorderStrokeWidth
        // Cliqz: use title font same as one in normal mode
        theme.font = TitleFont//UIConstants.DefaultChromeBoldFont
		// Cliqz: Changed background&text colors and insets of TabsButton in Private Mode according to requirements (Commented out original color)
        theme.backgroundColor = UIColor.clearColor() // UIConstants.AppBackgroundColor
        theme.textColor = UIColor.whiteColor() // UIConstants.PrivateModePurple
		theme.insets = TitleInsets // UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        theme.highlightButtonColor = UIConstants.PrivateModePurple
        theme.highlightTextColor = TabsButtonUX.TitleColor
        theme.highlightBorderColor = UIConstants.PrivateModePurple
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor = BorderColor
        theme.borderWidth = BorderStrokeWidth
        theme.font = TitleFont
		// Cliqz: Changed text colors and backgroundColor of TabsButton in Normal Mode according to requirements (Commented out original color)
        theme.backgroundColor = UIColor.clearColor() //TitleBackgroundColor
        theme.textColor = UIColor.blackColor() // TitleColor
        theme.insets = TitleInsets
        theme.highlightButtonColor = TabsButtonUX.TitleColor
        theme.highlightTextColor = TabsButtonUX.TitleBackgroundColor
        theme.highlightBorderColor = TabsButtonUX.TitleBackgroundColor
        themes[Theme.NormalMode] = theme

        return themes
    }()
}
//Cliqz: Change the super class of TabsButton to UIButton to be included into both TabToolBar and URLBar
//class TabsButton: UIControl {
class TabsButton: UIButton {
    private var theme: Theme = TabsButtonUX.Themes[Theme.NormalMode]!
    
    override var highlighted: Bool {
        didSet {
            //Cliqz: disable highlighting effect for tabs button
//            if highlighted {
//                borderColor = theme.highlightBorderColor!
//                titleBackgroundColor = theme.highlightButtonColor
//                textColor = theme.highlightTextColor
//            } else {
                borderColor = theme.borderColor!
                titleBackgroundColor = theme.backgroundColor
                textColor = theme.textColor
//            }
        }
    }
    // Cliqz: renamed titleLabel to title so as not to confilect with titleLabel? from UIButton super class
//    lazy var titleLabel: UILabel = {
    lazy var title: UILabel = {
        let label = UILabel()
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = false
        return label
    }()

    lazy var insideButton: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.userInteractionEnabled = false
        return view
    }()

    private lazy var labelBackground: UIView = {
        let background = UIView()
        background.layer.cornerRadius = TabsButtonUX.CornerRadius
        background.userInteractionEnabled = false
        return background
    }()

    private lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = TabsButtonUX.BorderStrokeWidth
        border.cornerRadius = TabsButtonUX.CornerRadius
        border.userInteractionEnabled = false
        return border
    }()

    private var buttonInsets: UIEdgeInsets = TabsButtonUX.TitleInsets

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubview(labelBackground)
        insideButton.addSubview(borderView)
        // Cliqz: use new variable title instead of old one titleLabel
//        insideButton.addSubview(titleLabel)
        insideButton.addSubview(title)
        addSubview(insideButton)
        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton
    }

    override func updateConstraints() {
        super.updateConstraints()
        labelBackground.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        borderView.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        // Cliqz: use new variable title instead of old one titleLabel
        title.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        insideButton.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clone() -> UIView {
        let button = TabsButton()
        button.accessibilityLabel = accessibilityLabel
        // Cliqz: use new variable title instead of old one titleLabel
        /*
         button.titleLabel.text = titleLabel.text
         
         // Copy all of the styable properties over to the new TabsButton
         button.titleLabel.font = titleLabel.font
         button.titleLabel.textColor = titleLabel.textColor
         button.titleLabel.layer.cornerRadius = titleLabel.layer.cornerRadius

         */
        button.title.text = title.text

        // Copy all of the styable properties over to the new TabsButton
        button.title.font = title.font
        button.title.textColor = title.textColor
        button.title.layer.cornerRadius = title.layer.cornerRadius

        button.labelBackground.backgroundColor = labelBackground.backgroundColor
        button.labelBackground.layer.cornerRadius = labelBackground.layer.cornerRadius

        button.borderView.strokeWidth = borderView.strokeWidth
        button.borderView.color = borderView.color
        button.borderView.cornerRadius = borderView.cornerRadius
        return button
    }
}

extension TabsButton: Themeable {
    func applyTheme(themeName: String) {

        guard let theme = TabsButtonUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        borderColor = theme.borderColor!
        borderWidth = theme.borderWidth!
        titleFont = theme.font
        titleBackgroundColor = theme.backgroundColor
        textColor = theme.textColor
        insets = theme.insets!

        self.theme = theme
    }
}

// MARK: UIAppearance
extension TabsButton {
    dynamic var borderColor: UIColor {
        get { return borderView.color }
        set { borderView.color = newValue }
    }

    dynamic var borderWidth: CGFloat {
        get { return borderView.strokeWidth }
        set { borderView.strokeWidth = newValue }
    }

    dynamic var textColor: UIColor? {
        // Cliqz: use new variable title instead of old one titleLabel
//        get { return titleLabel.textColor }
//        set { titleLabel.textColor = newValue }
        
        get { return title.textColor }
        set { title.textColor = newValue }
    }

    dynamic var titleFont: UIFont? {
        // Cliqz: use new variable title instead of old one titleLabel
//        get { return titleLabel.font }
//        set { titleLable.font = newValue }

        get { return title.font }
        set { title.font = newValue }
    }

    dynamic var titleBackgroundColor: UIColor? {
        get { return labelBackground.backgroundColor }
        set { labelBackground.backgroundColor = newValue }
    }

    dynamic var insets : UIEdgeInsets {
        get { return buttonInsets }
        set {
            buttonInsets = newValue
            setNeedsUpdateConstraints()
        }
    }
}
