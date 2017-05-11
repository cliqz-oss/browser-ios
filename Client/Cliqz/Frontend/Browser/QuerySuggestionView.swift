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
    fileprivate var currentText = ""
    
    
    init() {
        let applicationFrame = UIScreen.main.applicationFrame
        let frame = CGRect(x: 0.0, y: 0.0, width: applicationFrame.width, height: kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .flexibleWidth
        self.backgroundColor = bgColor
        
        scrollView.frame = frame
        self.addSubview(self.scrollView)
        
        NotificationCenter.default.addObserver(self, selector:  #selector(QuerySuggestionView.viewRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        if !QuerySuggestions.isEnabled() {
            self.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didEnterText(_ text: String) {
        currentText = text
        
        guard QuerySuggestions.isEnabled() && OrientationUtil.isPortrait() else {
            self.isHidden = true
            return
        }
        
        guard !text.isEmpty else {
            clearSuggestions()
            return
        }

		QuerySuggestions.getSuggestions(text) { [weak self] (responseData) in
            self?.processSuggestionsResponse(text, responseData: responseData)
        }
        
    }
    
    //MARK:- Helper methods
    
    fileprivate func processSuggestionsResponse(_ query: String, responseData: Any) {
        let suggestionsResponse = responseData as! [String: Any]
        let suggestions = suggestionsResponse["suggestions"] as! [String]
        DispatchQueue.main.async(execute: {[weak self] in
            if query == self?.currentText {
                self?.clearSuggestions()
                self?.showSuggestions(suggestions)
            }
        })
    }
    
    
    fileprivate func clearSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
    }
    
    fileprivate func showSuggestions(_ suggestions: [String]) {
        
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
        
        let prefix = currentText
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
        
        if OrientationUtil.isPortrait() {
            self.isHidden = false
            self.didEnterText(currentText)
        } else {
            self.isHidden = true
            clearSuggestions()
        }
        
    }
}
