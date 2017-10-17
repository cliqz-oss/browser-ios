//
//  BackForwardUtil.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//


final class BackForwardListWatch {
    
    static let shared = BackForwardListWatch()
    
    var internalList: [String] = []
    
    func update(list:[String]) {
        //assumption: lists are aligned
        guard areAligned(l1: internalList, l2: list) else {
            NSException.init().raise()
            return
        }
        
        let diff = list.count - internalList.count
        
        if diff > 0 {
            //look at indexes internalList.count -> list.count - 1
            for i in internalList.count..<list.count {
                let url = list[i]
                StateManager.shared.handleAction(action: Action(data: ["url": url], type: .newVisit))
            }
        }
        
        internalList = list
    }
    
    func areAligned(l1: [String], l2: [String]) -> Bool {
        let min_count = min(l1.count, l2.count)
        
        for i in 0..<min_count {
            if l1[i] != l2[i] {
                return false
            }
        }
        
        return true
    }
}


//func update() {
//    let currIndicator = ">>> "
//    guard let obj = webView?.value(forKeyPath: "documentView.webView.backForwardList") else { return }
//    let history = (obj as AnyObject).description
//    //        let nsHistory = history as NSString
//
//    guard let nsHistory = history as NSString?, !(cachedHistoryStringLength > 0 && cachedHistoryStringLength == nsHistory.length &&
//        cachedHistoryStringPositionOfCurrentMarker > -1 &&
//        nsHistory.substring(with: NSMakeRange(cachedHistoryStringPositionOfCurrentMarker, currIndicator.characters.count)) == currIndicator) else {
//            // the history is unchanged (based on this guesstimate)
//            return
//    }
//
//    cachedHistoryStringLength = nsHistory.length
//
//    backForwardList = []
//
//    let regex = try! NSRegularExpression(pattern:"\\d+\\) +<WebHistoryItem.+> (http.+) ", options: [])
//    let result = regex.matches(in: nsHistory as String, options: [], range: NSMakeRange(0, nsHistory.length))
//    var i = 0
//    var foundCurrent = false
//    for match in result {
//        var extractedUrl = nsHistory.substring(with: match.rangeAt(1))
//        let parts = extractedUrl.components(separatedBy: " ")
//        if parts.count > 1 {
//            extractedUrl = parts[0]
//        }
//        guard let url = NSURL(string: extractedUrl) else { continue }
//        let item = LegacyBackForwardListItem(url: url as URL)
//        backForwardList.append(item)
//
//        let rangeStart = match.range.location - currIndicator.characters.count
//        if rangeStart > -1 && nsHistory.substring(with: NSMakeRange(rangeStart, currIndicator.characters.count)) == currIndicator {
//            currentIndex = i
//            foundCurrent = true
//            cachedHistoryStringPositionOfCurrentMarker = rangeStart
//        }
//        i += 1
//    }
//
//    BackForwardListWatch.shared.update(list: backForwardList.map({a in a.url.absoluteString}))
//
//    if !foundCurrent {
//        currentIndex = 0
//    }
//}

