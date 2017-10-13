//
//  BackForwardUtil.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//


class BackForwardListWatch {
    
    static let shared = BackForwardListWatch()
    
    var internalSet: Set<String> = Set()
    
    func update(list:[String]) {
        let list_set = Set(list)
        
        let diff_set = list_set.subtracting(internalSet) //this is: list_set \ internalSet
        if diff_set.count > 0 {
            //there are new entries
        }
        
        internalSet = list_set
    }
    
}

//import UIKit
//
//class BackForwardUtil {
//    
//    enum EntryType: Equatable {
//        case browse(String)
//        case search
//        case domains
//        case history
//        
//        static func ==(lhs: EntryType, rhs: EntryType) -> Bool {
//            
//            switch lhs {
//            case .browse(let a):
//                switch rhs {
//                case .browse(let b):
//                    return a == b
//                default:
//                    return false
//                }
//            case .search:
//                switch rhs {
//                case .search:
//                    return true
//                default:
//                    return false
//                }
//            case .domains:
//                switch rhs {
//                case .domains:
//                    return true
//                default:
//                    return false
//                }
//            case .history:
//                switch rhs {
//                case .history:
//                    return true
//                default:
//                    return false
//                }
//            }
//            
//        }
//    }
//    
//    static let shared = BackForwardUtil()
//    
//    private var internalArray: [EntryType] = []
//    private var currentIndex: Int = 0
//    
//    func currentEntry() -> EntryType {
//        return internalArray[currentIndex]
//    }
//    func previousEntry() -> EntryType? {
//        guard isValid(index: currentIndex - 1) else {
//            return nil
//        }
//        
//        return internalArray[currentIndex - 1]
//    }
//    
//    func nextEntry() -> EntryType? {
//        guard isValid(index: currentIndex + 1) else {
//            return nil
//        }
//        
//        return internalArray[currentIndex + 1]
//    }
//    
//    func incrementCurrentIndex() {
//        guard isValid(index: currentIndex + 1) else {
//            NSException.init().raise()
//            return
//        }
//        currentIndex += 1
//    }
//    
//    func decrementCurrentIndex() {
//        guard isValid(index: currentIndex - 1) else {
//            NSException.init().raise()
//            return
//        }
//        currentIndex -= 1
//    }
//    
//    func addEntry(entry: EntryType) {
//        
//        //never add history if the current state is different that browse
//        //tab manager is supposed to become a singleton, so this will become simpler
//        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager, let currentTab = tabManager.selectedTab {
//            //tab Manager has to become a singleton. There cannot be 2 tab managers.
//            if entry == .history && BackForwardNavigation.shared.currentState(tab: currentTab)?.contentState != .browse {
//                return
//            }
//        }
//        
//        internalArray.append(entry)
//        if currentIndex == internalArray.count - 2 {
//            incrementCurrentIndex()
//        }
//        
//        //there is an edge case. Say the webview is loaded with a url. Let's call this url: urlWebView.
//        //If I am on the detail view and I select the history entry with urlHistory == urlWebViewm then only the browse state without a history entry is added.
//        //So instead of having: [browse, history] in the internal array, I will have [browse]. To correct this, I need to add the history entry if the urls coincide
//        switch entry {
//        case .browse(let urlStr):
//            if BackForwardListHelper.shared.currentUrlStr == urlStr {
//                addEntry(entry: .history)
//            }
//        default:
//            break
//        }
//        
//        //if there is a browse entry before the history entry, I should remove the browse entry
//        if let prevEntry = previousEntry() {
//            switch currentEntry() {
//            case .history:
//                switch prevEntry {
//                case .browse(_):
//                    removeEntry(index: currentIndex - 1)
//                default:
//                    break
//                }
//            default:
//                break
//            }
//        }
//
//    }
//    
//    func removeEntry(index: Int) {
//        guard isValid(index: index) else {
//            return
//        }
//        
//        internalArray.remove(at: index)
//        decrementCurrentIndex()
//    }
//    
//    func isValid(index: Int) -> Bool {
//        if index >= 0 && index < internalArray.count {
//            return true
//        }
//        return false
//    }
//    
//}
//
//class BackForwardListHelper {
//    
//    static let shared = BackForwardListHelper()
//    
//    private var backForwardListLength: Int = 0
//    
//    var currentUrlStr: String = ""
//    
//    //this is not correct. The backForward list can also shrink. This does not account for it. 
//    func update(count: Int, latestUrlStr: String) {
//        let diff = count - backForwardListLength
//        
//        if diff > 0 {
//            for _ in 0..<diff {
//                BackForwardUtil.shared.addEntry(entry: .history)
//            }
//            
//            backForwardListLength = count
//        }
//        
//        currentUrlStr = latestUrlStr
//    }
//    
//}

