//
//  ABTestsManager.swift
//  Client
//
//  Created by Mahmoud Adam on 3/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ABTestsManager: NSObject {
    //MARK:- Constants
    fileprivate static let checkURL = "https://stats.cliqz.com/abtests/check"
    fileprivate static let dispatchQueue = DispatchQueue(label: "com.cliqz.abtests", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate static let ABTestsKey = "ABTests"
    
    //MARK:- Public APIs
    class func checkABTests(_ sessionId: String) {
        ConnectionManager.sharedInstance.sendRequest(.get,
                                                     url: checkURL,
                                                     parameters: ["session": sessionId],
                                                     responseType: .jsonResponse,
                                                     queue: dispatchQueue,
                                                     onSuccess: { (response) in
                                                        if let tests = response as? [String: AnyObject] {
                                                            processABTests(tests)
                                                        }
                                                    }, onFailure: { (response, error) in
                                                        debugPrint("Could not check AB tests because of the following error \(error)")
                                                    })
    }
    
    
    class func getABTests() -> Any? {
        return LocalDataStore.objectForKey(ABTestsKey)
    }
    
    //MARK:- Private helper methods
    fileprivate class func processABTests(_ tests: [String: AnyObject]) {
        var oldTests = [String: AnyObject]()
        if let storedTests = getABTests() as? [String: AnyObject] {
            oldTests = storedTests
        }
        
        for (test, _) in tests {
            guard let testId = getTestId(test) else {
                continue
            }
            
            enterABTest(test)
            
            // remove the processed test from the old tests
            if let oldTest = getTest(oldTests, testId: testId) {
                oldTests.removeValue(forKey: oldTest)
            }
            
        }
        
        // iterate over the remaining old tests to call leave for each of them
        for (test, _) in oldTests {
            guard let testId = getTestId(test) else {
                continue
            }
            
            leaveABTest(testId)
        }
        
        // save the new tests in settings
        updateABTests(tests as AnyObject)
    }
    
    fileprivate class func updateABTests(_ newValue: AnyObject) {
        LocalDataStore.setObject(newValue, forKey: ABTestsKey)
    }
    
    fileprivate class func enterABTest(_ test: String) {
        switch test {
        default:
            return
        }
        
    }
    
    fileprivate class func leaveABTest(_ testId: String) {
        switch testId {
        default:
            return
        }
    }
    
    fileprivate class func getTestId(_ test: String) -> String? {
        let testComponents = test.components(separatedBy: "_")
        guard testComponents.count == 2  else {
            return nil
        }
        
        return testComponents[0]
    }
    
    fileprivate class func getTest(_ tests: [String: AnyObject], testId: String) -> String? {
        for (test, _) in tests {
            guard let currentTestId = getTestId(test) else {
                continue
            }
            if currentTestId == testId {
                return test
            }
        }
        return nil
    }
}
