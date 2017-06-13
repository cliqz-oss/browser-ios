//
//  ContentPolicyDetector.swift
//  jsengine
//
//  Created by Mahmoud Adam on 9/29/16.
//  Copyright © 2016 Cliqz GmbH. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ContentPolicyDetector {
    
    enum ContentType: Int {
        case other = 1
        case script
        case image
        case stylesheet
        case document = 6
        case subdocument
        case xmlhttpRequest = 11
        case font = 14
    }
    
    // MARK: reqular expressions
    fileprivate var RE_JS : NSRegularExpression?
    fileprivate var RE_CSS : NSRegularExpression?
    fileprivate var RE_IMAGE : NSRegularExpression?
    fileprivate var RE_FONT : NSRegularExpression?
    fileprivate var RE_HTML : NSRegularExpression?
    fileprivate var RE_JSON : NSRegularExpression?
    
    static let sharedInstance = ContentPolicyDetector()
    
    init () {
        do {
            try RE_JS = NSRegularExpression(pattern: "\\.js($|\\|?)", options: .caseInsensitive)
            try RE_CSS = NSRegularExpression(pattern: "\\.css($|\\|?)", options: .caseInsensitive)
            try RE_IMAGE = NSRegularExpression(pattern: "\\.(?:gif|png|jpe?g|bmp|ico)($|\\|?)", options: .caseInsensitive)
            try RE_FONT = NSRegularExpression(pattern: "\\.(?:ttf|woff)($|\\|?)", options: .caseInsensitive)
            try RE_HTML = NSRegularExpression(pattern: "\\.html?", options: .caseInsensitive)
            try RE_JSON = NSRegularExpression(pattern: "\\.json($|\\|?)", options: .caseInsensitive)
        } catch let error as NSError {
            debugPrint("Couldn't initialize regular expressions for detecting Content Policy because of the following error: \(error.description)")
        }
    }
    
    // MARK: - Public APIs
    func getContentPolicy(_ request: URLRequest, isMainDocument: Bool) -> Int {
        // set default value
        var contentPolicy : ContentType?
        
        // Check if the request is the Main Document
        if (isMainDocument) {
            contentPolicy = .document
        } else if let acceptHeader = request.value(forHTTPHeaderField: "Accept") {
            if acceptHeader.range(of: "text/css") != nil {
                contentPolicy = .stylesheet
            } else if acceptHeader.range(of: "image/*") != nil || acceptHeader.range(of: "image/webp") != nil {
                contentPolicy = .image
            } else if acceptHeader.range(of: "text/html") != nil {
                contentPolicy = .subdocument
            } else {
                // decide based on the URL pattern
                contentPolicy = getContentPolicy(request.url)
            }
        } else {
            // decide based on the URL pattern
            contentPolicy = getContentPolicy(request.url)
        }
        return contentPolicy!.rawValue
    }
    
    // MARK: - Private helper methods
    fileprivate func getContentPolicy(_ url: URL?) -> ContentType {
        
        // set default value
        var contentPolicy: ContentType = .xmlhttpRequest
        //return contentPolicy
        if let urlString = url?.absoluteString {
            let range  = NSMakeRange(0, urlString.characters.count)
            
            if RE_JS?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .script
            } else if RE_CSS?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .stylesheet
            } else if RE_IMAGE?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .image
            } else if RE_FONT?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .font
            } else if RE_HTML?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .subdocument
            } else if RE_JSON?.numberOfMatches(in: urlString, options: [], range: range) > 0 {
                contentPolicy = .other
            }
        }
        return contentPolicy
    }
    
}
