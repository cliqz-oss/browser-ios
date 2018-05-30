//
//  SearchBarTelemetryHelper.swift
//  Client
//
//  Created by Mahmoud Adam on 11/19/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class SearchBarTelemetryHelper: NSObject {
    var lastTypingTime = NSDate.getCurrentMillis()
    var urlbarFocusTime = NSDate.getCurrentMillis()
    
    //MARK: - Singltone
    static let sharedInstance = SearchBarTelemetryHelper()
    
    func logQueryInteractionEvent(newText: String, oldText: String, range: NSRange) {
        lastTypingTime = NSDate.getCurrentMillis()
        
        let stringLength = newText.characters.count
        let oldLength = oldText.characters.count
        
        if stringLength == 0 {
            // keystroke_del
            // to handel selection deletion
            var currentLength = range.location
            let suffixLength = oldLength - range.location - range.length
            if suffixLength > 0 {
                currentLength += suffixLength
            }
            // if user delete the auto complete part
            if currentLength > oldLength {
                currentLength = oldLength
            }

            TelemetryLogger.sharedInstance.logEvent(.QueryInteraction("keystroke_del", currentLength))
        } else if stringLength == 1 {
            // key_stroke
            // Disabled sending key_stroke as it is hard to remove it from the JavaScript code for now
//            let currentLength = oldLength + 1
//            TelemetryLogger.sharedInstance.logEvent(.QueryInteraction("key_stroke", currentLength))
        } else if stringLength > 1 {
            // paste
            let currentLength = oldLength + stringLength - range.length
            TelemetryLogger.sharedInstance.logEvent(.QueryInteraction("paste", currentLength))
        }
    }
    func logUrlBarFocusEvent() {
        urlbarFocusTime = NSDate.getCurrentMillis()
        
        //TODO context
        let context = ""
        TelemetryLogger.sharedInstance.logEvent(.UrlFocusBlur("urlbar_focus", context))
    }
    
    class func logUrlBarBlurEvent() {
        TelemetryLogger.sharedInstance.logEvent(.UrlFocusBlur("urlbar_blur", ""))
    }
    
    func logResultEnterEvent(enteredText: String, autoCompletedText: String) {
        let queryLength = enteredText.characters.count
        let autocompletedLength = autoCompletedText.characters.count
        let autocompletedUrl = URIFixup.getURL(autoCompletedText)?.absoluteString
        let now = NSDate.getCurrentMillis()
        let reactionTime = now - lastTypingTime
        let urlbarTime = now - urlbarFocusTime
        
        TelemetryLogger.sharedInstance.logEvent(.ResultEnter(queryLength, autocompletedLength, autocompletedUrl, reactionTime, urlbarTime))
    }
}
