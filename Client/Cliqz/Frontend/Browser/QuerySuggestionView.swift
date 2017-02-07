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
    private let querySuggestionsApiUrl = "http://suggest.test.cliqz.com:7000/suggest"
    private let dispatchQueue = dispatch_queue_create("com.cliqz.QuerySuggestion", DISPATCH_QUEUE_SERIAL)
    
    private let kViewHeight: CGFloat = 44
    private let scrollView = UIScrollView()
    private let suggestionFont = UIFont.systemFontOfSize(17)
    private let fontAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(17)]
    private let bgColor = UIColor(rgb: 0xADB5BD)
    private let separatorBgColor = UIColor(rgb: 0xC7CBD3)
    
    //MARK:- instance variables
    weak var delegate : QuerySuggestionDelegate? = nil
    private var currentText: String?
    
    
    init() {
        let applicationFrame = UIScreen.mainScreen().applicationFrame
        let frame = CGRectMake(0.0, 0.0, CGRectGetWidth(applicationFrame), kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth
        self.backgroundColor = bgColor
        
        scrollView.frame = frame
        self.addSubview(self.scrollView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:  #selector(QuerySuggestionView.viewRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didEnterText(text: String) {
        currentText = text
        
        guard !text.isEmpty else {
            clearSuggestions()
            return
        }

        ConnectionManager.sharedInstance
            .sendPlainPostRequestWithBody(querySuggestionsApiUrl,
                                     body: "query=\(text)",
                                     queue: self.dispatchQueue,
                                     onSuccess: { [weak self] responseData in
                                        self?.processSuggestionsResponse(text, responseData: responseData)
                                     },
                                     onFailure: {(data, error) in
                                        print(error)
                                     })
        
        
    }
    //MARK:- Helper methods
    
    private func processSuggestionsResponse(query: String, responseData: AnyObject) {
        let suggestionsResponse = responseData as! [String: AnyObject]
        let suggestions = suggestionsResponse["suggestions"] as! [String]
        dispatch_async(dispatch_get_main_queue(), {[weak self] in
            if query == self?.currentText {
                self?.removeOldSuggestions()
                self?.showSuggestions(suggestions)
            }
        })
    }
    
    private func clearSuggestions() {
        removeOldSuggestions()
    }
    
    private func removeOldSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
    }
    
    private func showSuggestions(suggestions: [String]) {
        var x: CGFloat = 10
        var index = 0
        
        for suggestion in suggestions {
            let suggestionWidth = getWidth(suggestion)
            // show Max 3 suggestions which does not exceed screen width
            if x + suggestionWidth > self.frame.width || index > 2 {
                break;
            }
            
            // Adding vertical separator between suggestions
            if index > 0 {
                let verticalSeparator = createVerticalSeparator(x)
                scrollView.addSubview(verticalSeparator)
            }
            // Adding the suggestion button
            let suggestionButton = createSuggestionButton(x, suggestion: suggestion, suggestionWidth: suggestionWidth)
            scrollView.addSubview(suggestionButton)
            
            // increment step
            x = x + suggestionWidth + 21
            index = index + 1
        }
    }
    
    private func createVerticalSeparator(x: CGFloat) -> UIView {
        let verticalSeparator = UIView()
        verticalSeparator.frame = CGRectMake(x-11, 0, 1, kViewHeight)
        verticalSeparator.backgroundColor = separatorBgColor
        return verticalSeparator;
    }
    
    private func createSuggestionButton(x: CGFloat, suggestion: String, suggestionWidth: CGFloat) -> UIButton {
        let button = UIButton(type: .Custom)
        button.setTitle(suggestion, forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel?.font = suggestionFont
        button.frame = CGRectMake(x, 0, suggestionWidth, kViewHeight)
        button.addTarget(self, action: #selector(selectSuggestion(_:)), forControlEvents: .TouchUpInside)
        return button
    }
    
    private func getWidth(suggestion: String) -> CGFloat {
        let sizeOfString = (suggestion as NSString).sizeWithAttributes(fontAttributes)
        return sizeOfString.width
    }
    
    @objc private func selectSuggestion(button: UIButton) {
        
        guard let suggestion = button.titleLabel?.text else {
            return
        }
        delegate?.autoComplete(suggestion + " ")
    }
    
    @objc private func viewRotated() {
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
            self.hidden = true
        } else if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
            self.hidden = false
        }
        
    }
}
