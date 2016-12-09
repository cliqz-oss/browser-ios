//
//  FooterActivityItemProvider.swift
//  Client
//
//  Created by Mahmoud Adam on 2/15/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//
import Foundation

/// This Activity Item Provider subclass does two things that are non-standard behaviour:
///
/// * We return NSNull if the calling activity is not supposed to see the title. For example the Copy action, which should only paste the URL.
///

class FooterActivityItemProvider: UIActivityItemProvider {
    static let activityTypesToIgnore = [UIActivityTypeCopyToPasteboard, UIActivityTypeMessage, UIActivityTypePostToTwitter]
    
    init(footer: String) {
        super.init(placeholderItem: footer)
    }
    
    override func item() -> AnyObject {
        if let activityType = activityType {
            if FooterActivityItemProvider.activityTypesToIgnore.contains(activityType) {
                return NSNull()
            }
        }
        return placeholderItem!
    }
}

