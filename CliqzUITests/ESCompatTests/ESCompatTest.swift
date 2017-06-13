//
//  ESCompatTest.swift
//  Client
//
//  Created by Mahmoud Adam on 10/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest
import JavaScriptCore

class ESCompatTest: XCTestCase {
    
    // MARK: - Private Properties
    private var category : String?
    private var testName : String?
    private var testFn : String?
    private var context : JSContext?
    private var timers :[Int: NSTimer]?
    private var timerCounter = 0
    
    
    private let dispatchQueue = dispatch_queue_create("com.cliqz.JSCore.UnitTesting", DISPATCH_QUEUE_SERIAL)
    
    
    // MARK: - Setup and Tear down
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        context = JSContext()
        timers = [Int: NSTimer]()
        timerCounter = 0
        
        configureExceptionHandler()
        registerNativeMethods()
        polyfillMissingModules()
    }
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        context = nil
        timers = nil
        timerCounter = 0
    }
    
    
    // MARK: - Dynamic Test Creation
    
    class func loadTestsFromFile(fileName: String, testSuite: XCTestSuite) {
        let bundle = NSBundle(forClass: self)
        if let filePath = bundle.resourceURL?.URLByAppendingPathComponent(fileName) {
            
            do {
                if let jsonData = Data(contentsOf: filePath),
                    let categories = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? [[String: AnyObject]] {
                    
                    loadTestCategories(categories, testSuite: testSuite)
                }
            } catch let error as NSError {
                // files does not exist, do no thing
                print(error)
            }
            
        }
    }
    
    private class func loadTestCategories(categories: [[String: AnyObject]], testSuite: XCTestSuite) {
        for category in categories {
            if let categorySkip = category["skip"] as? Bool
                where categorySkip == true {
                continue
            }
            
            let categoryName = category["name"] as! String
            let testSpecs = category["subtests"] as! [[String: AnyObject]]
            for testSpec in testSpecs {
                let testName = testSpec["name"] as! String
                let testFn = testSpec["exec"] as! String
                if let testSpecSkip = testSpec["skip"] as? Bool
                    where testSpecSkip == true {
                    continue
                }
                
                addTest(categoryName, testName: testName, testFn: testFn, testSuite: testSuite)
            }
        }
    }
    
    private class func addTest(category: String, testName: String, testFn: String, testSuite: XCTestSuite) {
        // Returns an array of NSInvocation, which are not available in Swift, but still seems to work.
        let invocations = self.testInvocations()
        for invocation in invocations {
            
            // We can't directly use the NSInvocation type in our source, but it appears
            // that we can pass it on through.
            let testCase = ESCompatTest(invocation: invocation)
            
            // Normally the "parameterized" values are passed during initialization.
            // This is a "good enough" workaround. You'll see that I simply force unwrap
            // the optional at the callspot.
            testCase.category = category
            testCase.testName = testName
            testCase.testFn = testFn
            
            testSuite.addTest(testCase)
        }
    }
    
    // MARK: - Test Methods
    func testFeature() {
        if let category = self.category,
            let testName = self.testName,
            let testFn = self.testFn {
            let asyncTest = testFn.containsString("asyncTestPassed")
            context!.evaluateScript(self.testHelpers())
            if asyncTest == true {
                let asyncExpectation = expectationWithDescription("asyncTestPassed")
                
                let asyncTestPassed: @convention(block) () -> () = {
                    asyncExpectation.fulfill()
                }
                context!.setObject(unsafeBitCast(asyncTestPassed, AnyObject.self), forKeyedSubscript: "asyncTestPassed")
                
                context!.evaluateScript("(\(testFn))()")
                self.waitForExpectationsWithTimeout(10) { error in
                    XCTAssertNil(error, "\(category) :: \(testName)")
                }
                
            } else {
                let result = context!.evaluateScript("(\(testFn))()")
                XCTAssertTrue(result.toBool(), "\(category) :: \(testName)")
            }
        }
        
    }
    
    // MARK: - JSCore Helper methods
    private func configureExceptionHandler() {
        context!.exceptionHandler = { context, exception in
            print("JS Error: \(exception)")
        }
    }
    private func registerNativeMethods() {
        registerSetTimeoutMethod()
        registerSetIntervalMethod()
        registerClearIntervalMethod()
    }
    
    private func registerSetTimeoutMethod() {
        let setTimeout: @convention(block) (JSValue, Int) -> () = { function, timeoutMsec in
            let delay = Double(timeoutMsec) * Double(NSEC_PER_MSEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, self.dispatchQueue, {
                function.callWithArguments(nil)
            })
        }
        context!.setObject(unsafeBitCast(setTimeout, AnyObject.self), forKeyedSubscript: "setTimeout")
    }
    
    private func registerSetIntervalMethod() {
        let setInterval: @convention(block) (JSValue, Int) -> Int = { function, interval in
            let timerId = self.timerCounter
            self.timerCounter += 1
            let intervalInSeconds = interval / 1000
            let timeInterval = NSTimeInterval(intervalInSeconds)
            
			DispatchQueue.main.async {
                let timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
                                                                   target: self,
                                                                   selector: #selector(ESCompatTest.excuteJavaScriptFunction(_:)),
                                                                   userInfo: function,
                                                                   repeats: true)
                self.timers![timerId] = timer
            }
            
            return timerId
        }
        context!.setObject(unsafeBitCast(setInterval, AnyObject.self), forKeyedSubscript: "setInterval")
    }
    
    @objc private func excuteJavaScriptFunction(timer: NSTimer) -> () {
		dispatchQueue.async {
            if let function = timer.userInfo as? JSValue {
                function.callWithArguments(nil)
            }
        }
    }
    
    private func registerClearIntervalMethod() {
        let clearInterval: @convention(block) Int -> () = { timerId in
            if let timer = self.timers![timerId] {
                timer.invalidate()
            }
        }
        context!.setObject(unsafeBitCast(clearInterval, AnyObject.self), forKeyedSubscript: "clearInterval")
    }
    
    private func polyfillMissingModules() {
        //        // load promise
        //        loadJavascriptSource("es6-promise")
        //
        //        // core polyfill
        //        if #available(iOS 10, *) {
        //            loadJavascriptSource("core")
        //        } else if #available(iOS 9, *) {
        //        } else {
        //            loadJavascriptSource("core")
        //        }
    }
    
    private func loadJavascriptSource(sourceName: String) {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource(sourceName, ofType: "js"),
            script = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            context!.evaluateScript(script);
        }
    }
    
    private func testHelpers() -> String {
        return "var __createIterableObject = function (arr, methods) {\n" +
            "    methods = methods || {};\n" +
            "    if (typeof Symbol !== 'function' || !Symbol.iterator)\n" +
            "      return {};\n" +
            "    arr.length++;\n" +
            "    var iterator = {\n" +
            "      next: function() {\n" +
            "        return { value: arr.shift(), done: arr.length <= 0 };\n" +
            "      },\n" +
            "      'return': methods['return'],\n" +
            "      'throw': methods['throw']\n" +
            "    };\n" +
            "    var iterable = {};\n" +
            "    iterable[Symbol.iterator] = function(){ return iterator; };\n" +
            "    return iterable;\n" +
            "  };" +
        "var global = {__createIterableObject: __createIterableObject}";
    }
}
