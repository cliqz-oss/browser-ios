//
//  ContentPolicyDetector.swift
//  Client
//
//  Created by Mahmoud Adam on 9/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class ContentPolicyDetector: NSObject {
    // MARK: - Constants
    private static let NUM_OTHER = 1
    private static let NUM_SCRIPT = 2
    private static let NUM_IMAGE = 3
    private static let NUM_STYLESHEET = 4
    private static let NUM_DOCUMENT = 6
    private static let NUM_SUBDOCUMENT = 7
    private static let NUM_XMLHTTPREQUEST = 11
    private static let NUM_FONT = 14
    
    // MARK: reqular expressions
    private static var RE_JS : NSRegularExpression?
    private static var RE_CSS : NSRegularExpression?
    private static var RE_IMAGE : NSRegularExpression?
    private static var RE_FONT : NSRegularExpression?
    private static var RE_HTML : NSRegularExpression?
    private static var RE_JSON : NSRegularExpression?
    
    
    override class func initialize() {
        super.initialize()
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
    static func getContentPolicy(request: NSURLRequest, isMainDocument: Bool) -> Int {
        // set default value
        var contentPolicy : Int?
        
        // Check if the request is the Main Document
        if (isMainDocument) {
            contentPolicy = NUM_DOCUMENT
        } else if let acceptHeader = request.valueForHTTPHeaderField("Accept") {
            if acceptHeader.contains("text/css") {
                contentPolicy = NUM_STYLESHEET
            } else if acceptHeader.contains("image/*") || acceptHeader.contains("image/webp") {
                contentPolicy = NUM_IMAGE
            } else if acceptHeader.contains("text/html") {
                contentPolicy = NUM_SUBDOCUMENT
            } else {
                // decide based on the URL pattern
                contentPolicy = getContentPolicy(request.URL)
            }
        } else {
            // decide based on the URL pattern
            contentPolicy = getContentPolicy(request.URL)
        }
        return contentPolicy!
    }
    
    // MARK: - Private helper methods
    static private func getContentPolicy(url: NSURL?) -> Int {
        
        // set default value
        var contentPolicy = NUM_XMLHTTPREQUEST
        
        if let urlString = url?.absoluteString {
            let range  = NSMakeRange(0, urlString.characters.count)
            
            if RE_JS?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_SCRIPT
            } else if RE_CSS?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_STYLESHEET
            } else if RE_IMAGE?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_IMAGE
            } else if RE_FONT?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_FONT
            } else if RE_HTML?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_SUBDOCUMENT
            } else if RE_JSON?.numberOfMatchesInString(urlString, options: [], range: range) > 0 {
                contentPolicy = NUM_OTHER
            }
            
        }
        
        return contentPolicy
    }
    
}
