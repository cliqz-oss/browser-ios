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
    weak var delegate : QuerySuggestionDelegate? = nil
    let kViewHeight: CGFloat = 44
    let scrollView = UIScrollView()
    var suggestions = [String]()
    let suggestionFont = UIFont.systemFontOfSize(17)
    let fontAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(17)]
    private let dispatchQueue = dispatch_queue_create("com.cliqz.QuerySuggestion", DISPATCH_QUEUE_SERIAL)
    var currentText: String?
    let bgColor = UIColor(rgb: 0xADB5BD)
    
    init() {
        let applicationFrame = UIScreen.mainScreen().applicationFrame
        let frame = CGRectMake(0.0, 0.0, CGRectGetWidth(applicationFrame), kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth
        
        scrollView.frame = frame
//        scrollView.autoresizingMask = .FlexibleWidth
//        scrollView.delaysContentTouches = true
//        scrollView.pagingEnabled = true
//        scrollView.showsVerticalScrollIndicator = true
        self.addSubview(self.scrollView)
        
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
            .sendPlainPostRequestWithBody("http://suggest.test.cliqz.com:7000/suggest",
                                     body: "query=\(text)",
                                     queue: self.dispatchQueue,
                                     onSuccess: { [weak self] responseData in
                                        self?.processSuggestionsResponse(responseData)
                },
                                     onFailure: {(data, error) in
                                        print(error)
//                                        print(error)
            })
        
        
    }
    func processSuggestionsResponse(responseData: AnyObject) {
        let suggestionsResponse = responseData as! [String: AnyObject]
        let suggestions = suggestionsResponse["suggestions"] as! [String]
        dispatch_async(dispatch_get_main_queue(), {[weak self] in
            self?.removeOldSuggestions()
            self?.showSuggestions(suggestions)
        })
    }
    func clearSuggestions() {
        removeOldSuggestions()
        backgroundColor = UIColor.clearColor()
    }
    func removeOldSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
    }
    
    func showSuggestions(suggestions: [String]) {
        self.suggestions = suggestions
        
        var x: CGFloat = 10
        var index = 0
        
        for suggestion in suggestions {
            
            
            let width = getWidth(suggestion)
            
            if x + width > self.frame.width {
                break;
            }
            
            if index > 0 {
                let verticalSeparator = UIView()
                verticalSeparator.frame = CGRectMake(x-11, 0, 1, kViewHeight)
                verticalSeparator.backgroundColor = UIColor(rgb: 0xC7CBD3)
                scrollView.addSubview(verticalSeparator)
            }
            
            let button = UIButton(type: .Custom)
            button.setTitle(suggestion, forState: .Normal)
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            button.titleLabel?.font = suggestionFont
            button.frame = CGRectMake(x, 0, width, kViewHeight)
            button.tag = index
            button.addTarget(self, action: #selector(selectSuggestion(_:)), forControlEvents: .TouchUpInside)
            scrollView.addSubview(button)
            
            x = x + width + 21
            index = index + 1
            
        }
//        scrollView.contentSize = CGSizeMake(x, kViewHeight)
        if suggestions.count == 0 {
            self.backgroundColor = UIColor.clearColor()
        } else {
            self.backgroundColor = bgColor
        }
        
        if let text = currentText where text.isEmpty {
            clearSuggestions()
        }
    }
    
    func getWidth(suggestion: String) -> CGFloat {
        let sizeOfString = (suggestion as NSString).sizeWithAttributes(fontAttributes)
        return sizeOfString.width
    }
    
    func selectSuggestion(button: UIButton) {
        guard button.tag < suggestions.count else {
            return
        }
        let suggestion = suggestions[button.tag]
        delegate?.autoComplete(suggestion)
    }
}
