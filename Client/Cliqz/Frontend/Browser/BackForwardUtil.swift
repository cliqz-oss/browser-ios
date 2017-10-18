//
//  BackForwardUtil.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//


final class CurrentWebViewMonitor {
    static let shared = CurrentWebViewMonitor()
    
    var lastCanGoBack: Bool = false
    var lastCanGoForward: Bool = false

    var timer: Timer = Timer()

    init() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)//Timer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        timer.fire()
    }

    @objc private func update() {
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager, let currentWebView = tabManager.selectedTab?.webView {
            let canGoForward = currentWebView.canGoForward
            let canGoBack = currentWebView.canGoBack
            
            if canGoBack != lastCanGoBack || canGoForward != lastCanGoForward {
                //trigger and update
                StateManager.shared.handleAction(action: Action(type: .webNavigationUpdate))
                lastCanGoBack = canGoBack
                lastCanGoForward = canGoForward
            }
            
        }
    }
}

//final class BackForwardListWatch {
//    
//    static let shared = BackForwardListWatch()
//    
//    var internalDict: [Tab: [String]] = [:]
//    
//    func update(list:[String], tab:Tab) {
//        
//        let internalList: [String] = internalDict[tab] != nil ? internalDict[tab]! : []
//        
//        //assumption: lists are aligned
//        guard areAligned(l1: internalList, l2: list) else {
//            NSException.init().raise()
//            return
//        }
//        
//        let diff = list.count - internalList.count //if diff = 0, because of the guard I have list == internalList
//        
//        if diff > 0 {
//            //look at indexes internalList.count -> list.count - 1
//            for i in internalList.count..<list.count {
//                let url = list[i]
//                StateManager.shared.handleAction(action: Action(data: ["url": url], type: .newVisit))
//            }
//        }
//        else if diff < 0 {
//            if let states = BackForwardNavigation.shared.navigationStore.tabStateChains[tab]?.states {
//                for i in 0..<states.count {
//                    let index = states.count - 1 - i
//                    let state = states[index]
//                    if let state_url = state.stateData.url, state.contentState == .browse {
//                        if !list.contains(state_url) {
//                            BackForwardNavigation.shared.removeState(tab: tab, index: index)
//                        }
//                    }
//                }
//            }
//        }
//        
//        internalDict[tab] = list
//        
//    }
//    
//    func areAligned(l1: [String], l2: [String]) -> Bool {
//        let min_count = min(l1.count, l2.count)
//        
//        for i in 0..<min_count {
//            if l1[i] != l2[i] {
//                return false
//            }
//        }
//        
//        return true
//    }
//}
//
//final class CurrentWebViewMonitor {
//    static let shared = CurrentWebViewMonitor()
//    
//    var lastCurrentIndex: Int = 0
//    var lastBackForwardList: [String] = []
//    var lastListStr: String? = ""
//    var lastTab: Tab? = nil
//    
//    var cachedHistoryStringLength = 0
//    var cachedHistoryStringPositionOfCurrentMarker = -1
//    
//    var timer: Timer = Timer()
//    
//    init() {
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)//Timer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
//        timer.fire()
//    }
//    
//    @objc private func update() {
//        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager, let tab = tabManager.selectedTab, let currentWebView = tab.webView {
//            if let obj = currentWebView.value(forKeyPath: "documentView.webView.backForwardList") {
//                let history = (obj as AnyObject).description
//                
//                if tab != lastTab {
//                    lastListStr = "" //reset
//                    lastCurrentIndex = 0
//                }
//                
//                let (backForwardList, currentIndex) = self.extractListAndIndex(history: history, tab: tab)
//                
//                let sameList = lastBackForwardList == backForwardList
//                
//                if !sameList {
//                    BackForwardListWatch.shared.update(list: backForwardList, tab: tab)
//                }
//                
//                if currentIndex != lastCurrentIndex && sameList {
//                    
//                }
//                
//                lastBackForwardList = backForwardList
//                lastCurrentIndex = currentIndex
//                lastListStr = history
//                lastTab = tab
//            }
//        }
//    }
//    
//    private func extractListAndIndex(history: String?, tab: Tab) -> ([String],Int) {
//        
//        let currIndicator = ">>> "
//        var currentIndex: Int = 0
//        
//        guard let nsHistory = history as NSString?, lastListStr != history, !(self.cachedHistoryStringLength > 0 && self.cachedHistoryStringLength == nsHistory.length && self.cachedHistoryStringPositionOfCurrentMarker > -1 &&
//            nsHistory.substring(with: NSMakeRange(self.cachedHistoryStringPositionOfCurrentMarker, currIndicator.characters.count)) == currIndicator) else {
//                // the history is unchanged (based on this guesstimate)
//                return (self.lastBackForwardList, self.lastCurrentIndex)
//        }
//        
//        cachedHistoryStringLength = nsHistory.length
//        
//        var backForwardList: [String] = []
//        
//        let regex = try! NSRegularExpression(pattern:"\\d+\\) +<WebHistoryItem.+> (http.+) ", options: [])
//        let result = regex.matches(in: nsHistory as String, options: [], range: NSMakeRange(0, nsHistory.length))
//        var i = 0
//        var foundCurrent = false
//        for match in result {
//            var extractedUrl = nsHistory.substring(with: match.rangeAt(1))
//            let parts = extractedUrl.components(separatedBy: " ")
//            if parts.count > 1 {
//                extractedUrl = parts[0]
//            }
//            guard let url = URL(string: extractedUrl) else { continue }
//            backForwardList.append(url.absoluteString)
//            
//            let rangeStart = match.range.location - currIndicator.characters.count
//            if rangeStart > -1 && nsHistory.substring(with: NSMakeRange(rangeStart, currIndicator.characters.count)) == currIndicator {
//                currentIndex = i
//                foundCurrent = true
//                cachedHistoryStringPositionOfCurrentMarker = rangeStart
//            }
//            i += 1
//        }
//        
//        if !foundCurrent {
//            currentIndex = 0
//        }
//        
//        return (backForwardList, currentIndex)
//
//    }
//    
//}


