//
//  QuerySuggestionView.swift
//  Client
//
//  Created by Mahmoud Adam on 1/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
protocol QuerySuggestionDelegate : class {
    func autoComplete(suggestion: String)
}

class QuerySuggestionView: UIView {
    //MARK:- Constants
    private let kViewHeight: CGFloat = 44
    private let scrollView = UIScrollView()
    private let boldFontAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17), NSForegroundColorAttributeName: UIColor.whiteColor()]
    private let normalFontAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.whiteColor()]
    private let bgColor = UIColor(rgb: 0xADB5BD)
    private let separatorBgColor = UIColor(rgb: 0xC7CBD3)
    private let margin: CGFloat = 10
    
    //MARK:- instance variables
    weak var delegate : QuerySuggestionDelegate? = nil
    private var currentText = ""
    
    
    init() {
        let applicationFrame = UIScreen.mainScreen().applicationFrame
        let frame = CGRectMake(0.0, 0.0, CGRectGetWidth(applicationFrame), kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth
        self.backgroundColor = bgColor
        
        scrollView.frame = frame
        self.addSubview(self.scrollView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:  #selector(QuerySuggestionView.viewRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        if !QuerySuggestions.isEnabled() {
            self.hidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didEnterText(text: String) {
        currentText = text
        
        guard QuerySuggestions.isEnabled() && OrientationUtil.isPortrait() else {
            self.hidden = true
            return
        }
        
        guard !text.isEmpty else {
            clearSuggestions()
            return
        }

        QuerySuggestions.getSuggestions(text) { [weak self] responseData in
            self?.processSuggestionsResponse(text, responseData: responseData)
        }
        
    }
    
    //MARK:- Helper methods
    
    private func processSuggestionsResponse(query: String, responseData: AnyObject) {
        let suggestionsResponse = responseData as! [String: AnyObject]
        let suggestions = suggestionsResponse["suggestions"] as! [String]
        dispatch_async(dispatch_get_main_queue(), {[weak self] in
            if query == self?.currentText {
                self?.clearSuggestions()
                self?.showSuggestions(suggestions)
            }
        })
    }
    
    
    private func clearSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
    }
    
    private func showSuggestions(suggestions: [String]) {
        
        var index = 0
        var x: CGFloat = margin
        var difference:CGFloat = 0
        var offset:CGFloat = 0
        var displayedSuggestions = [(String, CGFloat)]()
        
        // Calcuate extra space after the last suggesion
        for suggestion in suggestions {
            if suggestion.trim() == self.currentText.trim() {
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
    
    private func getWidth(suggestion: String) -> CGFloat {
        let sizeOfString = (suggestion as NSString).sizeWithAttributes(boldFontAttributes)
        return sizeOfString.width + 5
    }

    private func createVerticalSeparator(x: CGFloat) -> UIView {
        let verticalSeparator = UIView()
        verticalSeparator.frame = CGRectMake(x-11, 0, 1, kViewHeight)
        verticalSeparator.backgroundColor = separatorBgColor
        return verticalSeparator;
    }
    
    private func createSuggestionButton(x: CGFloat, index: Int, suggestion: String, suggestionWidth: CGFloat) -> UIButton {
        let button = UIButton(type: .Custom)
        let suggestionTitle = getTitle(suggestion)
        button.setAttributedTitle(suggestionTitle, forState: .Normal)
        button.frame = CGRectMake(x, 0, suggestionWidth, kViewHeight)
        button.addTarget(self, action: #selector(selectSuggestion(_:)), forControlEvents: .TouchUpInside)
        button.tag = index
        return button
    }
    
    private func getTitle(suggestion: String) -> NSAttributedString {
        
        let prefix = currentText
        var title: NSMutableAttributedString!
        
        if let range = suggestion.rangeOfString(prefix) where range.startIndex == suggestion.startIndex {
            title = NSMutableAttributedString(string:prefix, attributes:normalFontAttributes)
            var suffix = suggestion
            suffix.replaceRange(range, with: "")
            title.appendAttributedString(NSAttributedString(string: suffix, attributes:boldFontAttributes))
            
        } else {
            title = NSMutableAttributedString(string:suggestion, attributes:boldFontAttributes)
        }
        return title
    }
    
    @objc private func selectSuggestion(button: UIButton) {
        
        guard let suggestion = button.titleLabel?.text else {
            return
        }
        delegate?.autoComplete(suggestion + " ")
        
        let customData = ["index" : button.tag]
        TelemetryLogger.sharedInstance.logEvent(.QuerySuggestions("click", customData))
    }
    
    @objc private func viewRotated() {
        guard QuerySuggestions.isEnabled() else {
            self.hidden = true
            return
        }
        
        if OrientationUtil.isPortrait() {
            self.hidden = false
            self.didEnterText(currentText)
        } else {
            self.hidden = true
            clearSuggestions()
        }
        
    }
}
