//
//  KeyboardAccessoryView.swift
//  Client
//
//  Created by Mahmoud Adam on 12/6/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import UIKit

enum AccessoryViewAction {
    case Tabs, History, Offrz, Favorite, DismissKeyboard
    case AutoComplete(String)
}

typealias HandelAccessoryAction = (AccessoryViewAction) -> Void

class KeyboardAccessoryView: UIView {

    static let sharedInstance = KeyboardAccessoryView()
    
    private let querySuggestionView = QuerySuggestionView()
    private let quickAccessBarView = QuickAccessBar()
    
    // MARK:- Static constants
    private let kViewHeight: CGFloat = 44
    private let KBackgroundColor = UIColor(rgb: 0xADB5BD)
    
    // MARK:- Initialization
    init() {
        let screenBounds = UIScreen.main.bounds
        let frame = CGRect(x: 0.0, y: 0.0, width: screenBounds.width, height: kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .flexibleWidth
        self.backgroundColor = KBackgroundColor//.withAlphaComponent(0.85)
        
        querySuggestionView.frame = frame
        querySuggestionView.isHidden = true
        self.addSubview(querySuggestionView)
        
        quickAccessBarView.frame = frame
        quickAccessBarView.configureBarComponents()
        quickAccessBarView.setupConstrains()
        quickAccessBarView.isHidden = false
        self.addSubview(quickAccessBarView)
        
        // initila state
        self.showQuickAccessBarView()
        
        // Notifications Observers
        NotificationCenter.default.addObserver(self, selector: #selector(showSuggestions) , name: QuerySuggestions.ShowSuggestionsNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func keyboardWillShow() {
        if !quickAccessBarView.isHidden {
            quickAccessBarView.updateButtonsStates()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:- Public APIs
    func updateCurrentQuery(_ query: String) {
        querySuggestionView.updateCurrentQuery(query)
        if query.isEmpty {
            self.quickAccessBarView.viewName = "home"
            self.showQuickAccessBarView()
        } else {
            self.quickAccessBarView.viewName = "cards"
        }
    }
    
    func setHandelAccessoryViewAction(_ handelAccessoryViewAction: @escaping HandelAccessoryAction) {
        querySuggestionView.handelAccessoryViewAction = handelAccessoryViewAction
        quickAccessBarView.handelAccessoryViewAction = handelAccessoryViewAction
    }
    
    // MARK:- Private Helpers
    @objc fileprivate func showSuggestions(notification: NSNotification) {
        
        guard
            let suggestionsData = notification.object as? [String: AnyObject],
            let query = suggestionsData["query"] as? String,
            let suggestions = suggestionsData["suggestions"] as? [String] else {
                
                self.showQuickAccessBarView()
                return
        }
        
        if querySuggestionView.shouldShowSuggestions(query: query, suggestions: suggestions) {
            querySuggestionView.displaySuggestions(query, suggestions: suggestions)
            self.showQuerySuggestionView()
        } else {
            querySuggestionView.updateSuggestions(suggestions)
            self.showQuickAccessBarView()
        }
        
    }
    
    @objc fileprivate func viewRotated() {
        guard OrientationUtil.isPortrait() else {
            self.isHidden = true
            return
        }
        
        self.isHidden = false
        
        if querySuggestionView.shouldShowSuggestions() {
            querySuggestionView.displayLastestSuggestions()
            showQuerySuggestionView()
        } else {
            showQuickAccessBarView()
        }
    }
    
    private func showQuickAccessBarView() {
        guard quickAccessBarView.isHidden == true else { return }
        
        quickAccessBarView.isHidden = false
        querySuggestionView.isHidden = true
        quickAccessBarView.updateButtonsStates()
        TelemetryLogger.sharedInstance.logEvent(.QuickAccessBar("show", quickAccessBarView.viewName, nil))

    }
    
    private func showQuerySuggestionView() {
        guard querySuggestionView.isHidden == true else { return }
        
        querySuggestionView.isHidden = false
        quickAccessBarView.isHidden = true
        TelemetryLogger.sharedInstance.logEvent(.QuickAccessBar("hide", quickAccessBarView.viewName, nil))
    }

}
