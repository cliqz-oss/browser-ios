//
//  QuickAccessBar.swift
//  Client
//
//  Created by Mahmoud Adam on 12/6/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import UIKit

class QuickAccessBar: UIView {
    let tabsButton = UIButton(type: .custom)
    let historyButton = UIButton(type: .custom)
    let offrzButton = UIButton(type: .custom)
    let favoriteButton = UIButton(type: .custom)
    let dismissKeyboardButton = UIButton(type: .custom)
    
    var handelAccessoryViewAction: HandelAccessoryAction?
    var hasUnreadOffrzAction: HasUnreadOffrzAction?
    var shouldShowOffrzAction: ShouldShowOffrzAction?
    var viewName = "home"
    
    // MARK:- Public APIs

    func configureBarComponents() {
        configureButton(tabsButton, imageName: "tabs_quick_access")
        configureButton(historyButton, imageName: "history_quick_access")
        configureButton(offrzButton, imageName: "offrz_active")
        configureButton(favoriteButton, imageName: "favorite_quick_access")
        configureButton(dismissKeyboardButton, imageName: "keyboard_dismiss")
    }
    
    func setupConstrains() {
        tabsButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.centerY.equalTo(self)
            make.width.equalTo(self).dividedBy(4)
        }
        
        historyButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(tabsButton.snp.right)
            make.width.equalTo(self).dividedBy(4)
        }
        
        favoriteButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(historyButton.snp.right)
            make.width.equalTo(self).dividedBy(4)
        }
        updateButtonsStates()
    }

    func updateButtonsStates() {
        let hasUnreadOffrz = self.hasUnreadOffrzAction?() ?? false
        let shouldShowOffrz = self.shouldShowOffrzAction?() ?? false

        if hasUnreadOffrz {
            offrzButton.setImage(UIImage(named: "offrz_active"), for: .normal)
        } else {
            offrzButton.setImage(UIImage(named: "offrz_inactive"), for: .normal)
        }

        offrzButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(favoriteButton.snp.right)
            if shouldShowOffrz {
                make.width.equalTo(self).dividedBy(4)
            } else {
                make.width.equalTo(0)
            }
        }
        
        dismissKeyboardButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(favoriteButton.snp.right)
            if shouldShowOffrz {
                make.width.equalTo(0)
            } else {
                make.width.equalTo(self).dividedBy(4)
            }
        }
        
    }
    
    // MARK:- Private Helpers
    
    private func configureButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.addTarget(self, action: #selector(selectQuickAccessItem(_:)), for: .touchUpInside)
        self.addSubview(button)
    }
    
    @objc private func selectQuickAccessItem(_ button: UIButton) {
        var target = "NONE"
        if button == tabsButton {
            handelAccessoryViewAction?(.Tabs)
            target = "open_tabs"
        } else if button == historyButton {
            handelAccessoryViewAction?(.History)
            target = "history"
        } else if button == offrzButton {
            handelAccessoryViewAction?(.Offrz)
            target = "offrz"
        } else if button == favoriteButton {
            handelAccessoryViewAction?(.Favorite)
            target = "favorite"
        } else if button == dismissKeyboardButton {
            handelAccessoryViewAction?(.DismissKeyboard)
            target = "dimiss_keyboard"
        }
        TelemetryLogger.sharedInstance.logEvent(.QuickAccessBar("click", self.viewName, target))
    }
}
