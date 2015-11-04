//
//  StatisticsCollector.swift
//  Client
//
//  Created by Mahmoud Adam on 10/27/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class StatisticsCollector {

    //MARK: - Singltone
    static let sharedInstance = StatisticsCollector()
    private init() {
        
    }

    //MARK: - Private Variables
    private let padingLength = 25
    private var eventStatistics = [(String, Int)]()
    private var eventStartTimes = [String :Int64]()
    private var sumLatency = 0

    //MARK: - Public Variables
    var averageLatencyTime : Int {
        get{
            return sumLatency/eventStatistics.count
        }
    }
    
    //MARK: - Public Methods
    //MARK: Start/End Events
    func startEvent(eventName: String) {
        eventStartTimes[eventName] = getCurrentMillis()
    }
    
    func endEvent(eventName: String) {
        let endTime = getCurrentMillis()
        let startTime = eventStartTimes[eventName]!
        let latency = Int(endTime - startTime)
        sumLatency += latency
        eventStatistics.append((eventName, latency))
    }
    
    //MARK: Print/Clear Statistics
    func printStatistics() {
        // print header
        print("========== Statistics ========== ")
        let paddedHeader = "Query".stringByPaddingToLength(padingLength, withString: " ", startingAtIndex: 0)
        print("\(paddedHeader): latency")
        
        // print query/latency
        for (eventName, latency) in eventStatistics {
            let paddedEventName = eventName.stringByPaddingToLength(padingLength, withString: " ", startingAtIndex: 0)
            print("\(paddedEventName): \(latency)")
        }
        
        //print extra information
        print("Average latency time : \(self.averageLatencyTime)")
    }
    
    func clearStatistics() {
        eventStatistics = [(String, Int)]()
        eventStartTimes = [String :Int64]()
    }
    
    //MARK: General Utils
    func getCurrentMillis()->Int64 {
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
}
