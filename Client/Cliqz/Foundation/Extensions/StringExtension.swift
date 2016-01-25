//
//  StringExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

extension String {
    
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
    
    
    func trim() -> String {
        let newString = self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return newString
    }
    
    static func generateRandomString(length: Int, alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") -> String {
        var randomString = ""
        
        let rangeLength = UInt32 (alphabet.characters.count)
        
        for (var i=0; i < length; i++){
            let randomIndex = Int(arc4random_uniform(rangeLength))
            randomString.append(alphabet[alphabet.startIndex.advancedBy(randomIndex)])
        }
        
        return String(randomString)
    }
    
    func replace(string:String, replacement:String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    func removeWhitespaces() -> String {
        return self.replace(" ", replacement: "")
    }
    
    func escapeURL() -> String {
        let allowedCharacterSet = NSMutableCharacterSet()
        allowedCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLQueryAllowedCharacterSet())
        allowedCharacterSet.removeCharactersInString("=")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet)!
    }
	
	// Cliqz added extra URL encoding methods because stringByAddingPercentEncodingWithAllowedCharacters doesn't encodes &
	func encodeURL() -> String {
		return CFURLCreateStringByAddingPercentEscapes(nil,
			self as CFStringRef,
			nil,
			String("!*'\"();:@&=+$,/?%#[]% ") as CFStringRef, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as String
	}

}
