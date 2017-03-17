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
    private static let checkURL = "https://stats.cliqz.com/abtests/check"
    private static let dispatchQueue = dispatch_queue_create("com.cliqz.abtests", DISPATCH_QUEUE_CONCURRENT)
    private static let ABTestsKey = "ABTests"
    
    //MARK:- Public APIs
    class func checkABTests(sessionId: String) {
        ConnectionManager.sharedInstance.sendRequest(.GET,
                                                     url: checkURL,
                                                     parameters: ["session": sessionId],
                                                     responseType: .JSONResponse,
                                                     queue: dispatchQueue,
                                                     onSuccess: { (response) in
                                                        if let tests = response as? [String: AnyObject] {
                                                            processABTests(tests)
                                                        }
                                                    }, onFailure: { (response, error) in
                                                        print("Could not check AB tests because of the following error \(error)")
                                                    })
    }
    
    
    class func getABTests() -> AnyObject? {
        return LocalDataStore.objectForKey(ABTestsKey)
    }
    
    //MARK:- Private helper methods
    private class func processABTests(tests: [String: AnyObject]) {
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
                oldTests.removeValueForKey(oldTest)
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
        updateABTests(tests)
    }
    
    private class func updateABTests(newValue: AnyObject) {
        LocalDataStore.setObject(newValue, forKey: ABTestsKey)
    }
    
    private class func enterABTest(test: String) {
        switch test {
        case "1089_A":
            LocalDataStore.setObject(false, forKey: LocalDataStore.enableQuerySuggestionKey)
        case "1089_B":
            LocalDataStore.setObject(true, forKey: LocalDataStore.enableQuerySuggestionKey)
            
        default:
            return
        }
        
    }
    
    private class func leaveABTest(testId: String) {
        switch testId {
        case "1089":
            LocalDataStore.removeObjectForKey(LocalDataStore.enableQuerySuggestionKey)
        default:
            return
        }
    }
    
    private class func getTestId(test: String) -> String? {
        let testComponents = test.componentsSeparatedByString("_")
        guard testComponents.count == 2  else {
            return nil
        }
        
        return testComponents[0]
    }
    
    private class func getTest(tests: [String: AnyObject], testId: String) -> String? {
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
