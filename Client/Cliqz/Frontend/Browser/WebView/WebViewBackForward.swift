/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class LegacyBackForwardListItem {
    
	var url: URL {
        didSet {
            checkForLocalWebserver()
        }
    }
	var initialURL: URL
    var title:String = "" {
        didSet {
            checkForLocalWebserver()
        }
    }
    
    private func checkForLocalWebserver()  {
        if AboutUtils.isAboutURL(url) && !title.isEmpty {
            title = ""
        }
    }
    
    init(url: URL) {
        self.url = url
        // In order to mimic the built-in API somewhat, the initial url is stripped of mobile site
        // parts of the host (mobile.nytimes.com -> initial url is nytimes.com). The initial url
        // is the pre-page-forwarding url
        let normal = url.scheme ?? "http" + "://" + (url.normalizedHostAndPath() ?? url.absoluteString)
        initialURL = URL(string: normal) ?? url
    }
}

extension LegacyBackForwardListItem: Equatable {}
func == (lhs: LegacyBackForwardListItem, rhs: LegacyBackForwardListItem) -> Bool {
    return lhs.url.absoluteString == rhs.url.absoluteString;
}


class WebViewBackForwardList {
    
    var currentIndex: Int = 0
    var backForwardList: [LegacyBackForwardListItem] = []
    weak var webView: CliqzWebView?
    var cachedHistoryStringLength = 0
    var cachedHistoryStringPositionOfCurrentMarker = -1
    
    init(webView: CliqzWebView) {
        self.webView = webView
    }
    
    private func isSpecial(_url: URL?) -> Bool {
        guard let url = _url else { return false }
        #if !TEST
            return url.absoluteString.range(of: WebServer.sharedInstance.base) != nil
        #else
            return false
        #endif
    }
    
    func update() {
        let currIndicator = ">>> "
        guard let obj = webView?.value(forKeyPath: "documentView.webView.backForwardList") else { return }
        let history = (obj as AnyObject).description
//        let nsHistory = history as NSString
		
        guard let nsHistory = history as NSString?, !(cachedHistoryStringLength > 0 && cachedHistoryStringLength == nsHistory.length &&
            cachedHistoryStringPositionOfCurrentMarker > -1 &&
			nsHistory.substring(with: NSMakeRange(cachedHistoryStringPositionOfCurrentMarker, currIndicator.characters.count)) == currIndicator) else {
            // the history is unchanged (based on this guesstimate)
            return
        }  
        
        cachedHistoryStringLength = nsHistory.length
        
        backForwardList = []
        
        let regex = try! NSRegularExpression(pattern:"\\d+\\) +<WebHistoryItem.+> (http.+) ", options: [])
        let result = regex.matches(in: nsHistory as String, options: [], range: NSMakeRange(0, nsHistory.length))
        var i = 0
        var foundCurrent = false
        for match in result {
			var extractedUrl = nsHistory.substring(with: match.rangeAt(1))
            let parts = extractedUrl.components(separatedBy: " ")
            if parts.count > 1 {
                extractedUrl = parts[0]
            }
            guard let url = NSURL(string: extractedUrl) else { continue }
            let item = LegacyBackForwardListItem(url: url as URL)
            backForwardList.append(item)
            
            let rangeStart = match.range.location - currIndicator.characters.count
			if rangeStart > -1 && nsHistory.substring(with: NSMakeRange(rangeStart, currIndicator.characters.count)) == currIndicator {
                currentIndex = i
                foundCurrent = true
                cachedHistoryStringPositionOfCurrentMarker = rangeStart
            }
            i += 1
        }
        
        //BackForwardListWatch.shared.update(list: backForwardList.map({a in a.url.absoluteString}))
        
        if !foundCurrent {
            currentIndex = 0
        }
    }
    
    var currentItem: LegacyBackForwardListItem? {
        get {
            guard let item = itemAtIndex(index: currentIndex) else {
                if let url = webView?.url {
                    let item = LegacyBackForwardListItem(url: url)
                    return item
                } else {
                    return nil
                }
            }
            return item
            
        }}
    
    var backItem: LegacyBackForwardListItem? {
        get {
            return itemAtIndex(index: currentIndex - 1)
        }}
    
    var forwardItem: LegacyBackForwardListItem? {
        get {
            return itemAtIndex(index: currentIndex + 1)
        }}
    
    func itemAtIndex(index: Int) -> LegacyBackForwardListItem? {
        if (backForwardList.count == 0 ||
            index > backForwardList.count - 1 ||
            index < 0) {
            return nil
        }
        return backForwardList[index]
    }
    
    var backList: [LegacyBackForwardListItem] {
        get {
            return (currentIndex > 0 && backForwardList.count > 0) ? Array(backForwardList[0..<currentIndex]) : []
        }}
    
    var forwardList: [LegacyBackForwardListItem] {
        get {
            return (currentIndex + 1 < backForwardList.count  && backForwardList.count > 0) ?
                Array(backForwardList[(currentIndex + 1)..<backForwardList.count]) : []
        }}
}
