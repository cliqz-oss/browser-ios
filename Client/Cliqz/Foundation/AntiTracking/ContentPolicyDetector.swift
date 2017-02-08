//
//  ContentPolicyDetector.swift
//  jsengine
//
//  Created by Mahmoud Adam on 9/29/16.
//  Copyright © 2016 Cliqz GmbH. All rights reserved.
//

import Foundation
import JavaScriptCore

class ContentPolicyDetector {
    
    enum ContentType: Int {
        case Other = 1
        case Script
        case Image
        case Stylesheet
        case Document = 6
        case Subdocument
        case XMLHTTPRequest = 11
        case Font = 14
    }
    
    // MARK: reqular expressions
    private var RE_JS : NSRegularExpression?
    private var RE_CSS : NSRegularExpression?
    private var RE_IMAGE : NSRegularExpression?
    private var RE_FONT : NSRegularExpression?
    private var RE_HTML : NSRegularExpression?
    private var RE_JSON : NSRegularExpression?
    
    static let sharedInstance = ContentPolicyDetector()
    
    init () {
        do {
            try RE_JS = NSRegularExpression(pattern: "\\.js($|\\|?)", options: .CaseInsensitive)
            try RE_CSS = NSRegularExpression(pattern: "\\.css($|\\|?)", options: .CaseInsensitive)
            try RE_IMAGE = NSRegularExpression(pattern: "\\.(?:gif|png|jpe?g|bmp|ico)($|\\|?)", options: .CaseInsensitive)
            try RE_FONT = NSRegularExpression(pattern: "\\.(?:ttf|woff)($|\\|?)", options: .CaseInsensitive)
            try RE_HTML = NSRegularExpression(pattern: "\\.html?", options: .CaseInsensitive)
            try RE_JSON = NSRegularExpression(pattern: "\\.json($|\\|?)", options: .CaseInsensitive)
        } catch let error as NSError {
            print("Couldn't initialize regular expressions for detecting Content Policy because of the following error: \(error.description)")
        }
    }
    
    // MARK: - Public APIs
    func getContentPolicy(request: NSURLRequest, isMainDocument: Bool) -> Int {
        // set default value
        var contentPolicy : ContentType?
        
        // Check if the request is the Main Document
        if (isMainDocument) {
            contentPolicy = .Document
        } else if let acceptHeader = request.valueForHTTPHeaderField("Accept") {
            if acceptHeader.rangeOfString("text/css") != nil {
                contentPolicy = .Stylesheet
            } else if acceptHeader.rangeOfString("image/*") != nil || acceptHeader.rangeOfString("image/webp") != nil {
                contentPolicy = .Image
            } else if acceptHeader.rangeOfString("text/html") != nil {
                contentPolicy = .Subdocument
            } else {
                // decide based on the URL pattern
                contentPolicy = getContentPolicy(request.URL)
            }
        } else {
            // decide based on the URL pattern
            contentPolicy = getContentPolicy(request.URL)
        }
        return contentPolicy!.rawValue
    }
    
    // MARK: - Private helper methods
    private func getContentPolicy(url: NSURL?) -> ContentType {
        
        // set default value
        var contentPolicy: ContentType = .XMLHTTPRequest
        //return contentPolicy
        if let urlString = url?.absoluteString {
            let range  = NSMakeRange(0, urlString.characters.count)
            
            if RE_JS?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Script
            } else if RE_CSS?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Stylesheet
            } else if RE_IMAGE?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Image
            } else if RE_FONT?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Font
            } else if RE_HTML?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Subdocument
            } else if RE_JSON?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = .Other
            }
        }
        return contentPolicy
    }
    
}
