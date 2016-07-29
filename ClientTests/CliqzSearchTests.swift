//
//  CliqzSearchTests.swift
//  Client
//
//  Created by Mahmoud Adam on 10/27/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import XCTest

class CliqzSearchEngineTests: XCTestCase {
    let cliqzSearch = CliqzSearch()
    let statisticsCollector = StatisticsCollector.sharedInstance
    let baseQueries = ["facebook", "google", "hello", "test", "weather munich"]
    lazy var queries: [String] = self.initialQueries()

    var expectation: XCTestExpectation?
    var searchedQueries = 0
    var currentQueryIndex = 0
    
    func initialQueries() -> [String]{
        var queries = [String]()
        for baseQuery in baseQueries {
            for index in 1...baseQuery.characters.count {
                let toIndex = baseQuery.startIndex.advancedBy(index)
                queries.append(baseQuery.substringToIndex(toIndex))
            }
        }
        return queries
    }
    
    override func setUp() {
        // clear Statistics from the singltone class
        searchedQueries = 0
        currentQueryIndex = 0
        statisticsCollector.clearStatistics()
        expectation = expectationWithDescription("Finished Search")
    }
    
    func testSearch(){
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("callSreach:"), userInfo: nil, repeats: true)
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }
    
    func callSreach(timer : NSTimer) {
        if currentQueryIndex < queries.count {
            let query = queries[currentQueryIndex++]
            cliqzSearch.startSearch(query) {
                (htmlResult) -> Void in
                self.searchedQueries++
                if self.searchedQueries == self.queries.count {
                    self.statisticsCollector.printStatistics()
                    self.expectation!.fulfill()
                    timer.invalidate()
                }
            }
        } else {
            timer.invalidate()
        }
        
    }
    
    
}
