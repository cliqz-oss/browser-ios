//
//  ES5CompatTest.swift
//  Client
//
//  Created by Mahmoud Adam on 10/5/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest

class ES5CompatTest: ESCompatTest {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: - Dynamic Test Creation
    
    override class func defaultTestSuite() -> XCTestSuite {
        
        let testSuite = XCTestSuite(name: NSStringFromClass(self))
        // load the tests from the local json file
        loadTestsFromFile("es5tests.json", testSuite: testSuite)
        
        return testSuite
    }
    
}
