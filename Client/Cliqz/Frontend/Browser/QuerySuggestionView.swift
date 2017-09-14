//
//  QuerySuggestionView.swift
//  Client
//
//  Created by Mahmoud Adam on 1/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
protocol QuerySuggestionDelegate : class {
    func autoComplete(_ suggestion: String)
}

class QuerySuggestionView: UIView {
    
    //MARK:- Constants
    fileprivate let kViewHeight: CGFloat = 44
    fileprivate let scrollView = UIScrollView()
    fileprivate let boldFontAttributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.white]
    fileprivate let normalFontAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 16), NSForegroundColorAttributeName: UIColor.white]
    fileprivate let bgColor = UIColor(rgb: 0xADB5BD)
    fileprivate let separatorBgColor = UIColor(rgb: 0xC7CBD3)
    fileprivate let margin: CGFloat = 10
    
    //MARK:- instance variables
    weak var delegate : QuerySuggestionDelegate? = nil
    
    private var currentQuery: String = ""
    private var currentSuggestions: [String] = []
    
    
    static let sharedInstance = QuerySuggestionView()
    
    init() {
        let screenBounds = UIScreen.main.bounds
        let frame = CGRect(x: 0.0, y: 0.0, width: screenBounds.width, height: kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .flexibleWidth
        self.backgroundColor = bgColor
        
        scrollView.frame = frame
        self.addSubview(self.scrollView)
        
        //initially hide the view until the user type query
        self.isHidden = true

        NotificationCenter.default.addObserver(self, selector: #selector(showSuggestions) , name: QuerySuggestions.ShowSuggestionsNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateCurrentQuery(_ query: String) {
        currentQuery = query
        if query.isEmpty {
            currentSuggestions.removeAll()
            clearSuggestions()
        }
    }
    
    func showSuggestions(notification: NSNotification) {
        
        guard let suggestionsData = notification.object as? [String: AnyObject],
            let query = suggestionsData["query"] as? String,
            let suggestions = suggestionsData["suggestions"] as? [String] else {
            return
        }
        
        clearSuggestions()
        displaySuggestions(query, suggestions: suggestions)
        
    }
    
    //MARK:- Helper methods
    fileprivate func clearSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
        self.isHidden = true
    }
    
    fileprivate func displaySuggestions(_ query: String, suggestions: [String]) {
        currentSuggestions = suggestions
        
        guard currentQuery == query && suggestions.count > 0 && OrientationUtil.isPortrait() else {
            return
        }
        self.isHidden = false
        
        var index = 0
        var x: CGFloat = margin
        var difference:CGFloat = 0
        var offset:CGFloat = 0
        var displayedSuggestions = [(String, CGFloat)]()
        
        // Calcuate extra space after the last suggesion
        for suggestion in suggestions {
            if suggestion.trim() == query.trim() {
                continue
            }
            let suggestionWidth = getWidth(suggestion)
            // show Max 3 suggestions which does not exceed screen width
            if x + suggestionWidth > self.frame.width || index > 2 {
                break;
            }
            // increment step
            x = x + suggestionWidth + 2*margin + 1
            index = index + 1
            displayedSuggestions.append((suggestion, suggestionWidth))
        }
        
        // distribute the extra space evenly on all suggestions
        difference = self.frame.width - x
        offset = round(difference/CGFloat(index))
        
        // draw the suggestions inside the view
        x = margin
        index = 0
        for (suggestion, width) in displayedSuggestions {
            let suggestionWidth = width + offset
            // Adding vertical separator between suggestions
            if index > 0 {
                let verticalSeparator = createVerticalSeparator(x)
                scrollView.addSubview(verticalSeparator)
            }
            // Adding the suggestion button
            let suggestionButton = createSuggestionButton(x, index: index, suggestion: suggestion, suggestionWidth: suggestionWidth)
            scrollView.addSubview(suggestionButton)
            
            // increment step
            x = x + suggestionWidth + 2*margin + 1
            index = index + 1
        }
        
        let availableCount = suggestions.count > 3 ? 3 : suggestions.count
        let customData = ["qs_show_count" : displayedSuggestions.count, "qs_available_count" : availableCount]
        TelemetryLogger.sharedInstance.logEvent(.QuerySuggestions("show", customData))
    }
    
    fileprivate func getWidth(_ suggestion: String) -> CGFloat {
        let sizeOfString = (suggestion as NSString).size(attributes: boldFontAttributes)
        return sizeOfString.width + 5
    }

    fileprivate func createVerticalSeparator(_ x: CGFloat) -> UIView {
        let verticalSeparator = UIView()
        verticalSeparator.frame = CGRect(x: x-11, y: 0, width: 1, height: kViewHeight)
        verticalSeparator.backgroundColor = separatorBgColor
        return verticalSeparator;
    }
    
    fileprivate func createSuggestionButton(_ x: CGFloat, index: Int, suggestion: String, suggestionWidth: CGFloat) -> UIButton {
        let button = UIButton(type: .custom)
        let suggestionTitle = getTitle(suggestion)
        button.setAttributedTitle(suggestionTitle, for: UIControlState())
        button.frame = CGRect(x: x, y: 0, width: suggestionWidth, height: kViewHeight)
        button.addTarget(self, action: #selector(selectSuggestion(_:)), for: .touchUpInside)
        button.tag = index
        return button
    }
    
    fileprivate func getTitle(_ suggestion: String) -> NSAttributedString {
        
        let prefix = currentQuery
        var title: NSMutableAttributedString!
        
        if let range = suggestion.range(of: prefix), range.lowerBound == suggestion.startIndex {
            title = NSMutableAttributedString(string:prefix, attributes:normalFontAttributes)
            var suffix = suggestion
            suffix.replaceSubrange(range, with: "")
            title.append(NSAttributedString(string: suffix, attributes:boldFontAttributes))
            
        } else {
            title = NSMutableAttributedString(string:suggestion, attributes:boldFontAttributes)
        }
        return title
    }
    
    @objc fileprivate func selectSuggestion(_ button: UIButton) {
        
        guard let suggestion = button.titleLabel?.text else {
            return
        }
        delegate?.autoComplete(suggestion + " ")
        
        let customData = ["index" : button.tag]
        TelemetryLogger.sharedInstance.logEvent(.QuerySuggestions("click", customData))
    }
    
    @objc fileprivate func viewRotated() {
        guard QuerySuggestions.isEnabled() else {
            self.isHidden = true
            return
        }

        clearSuggestions()
        if OrientationUtil.isPortrait() {
            self.displaySuggestions(currentQuery, suggestions: currentSuggestions)
        }
        
    }
}
