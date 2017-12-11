//
//  MigrationManager.swift
//  Client
//
//  Created by Tim Palade on 12/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Storage
import Shared
import RealmSwift

class MigrationManager {
    
    struct Visit {
        var title: String
        let url: NSURL
        let date: Date?
    }
    
    let files = ProfileFileAccessor(localName: "profile")
    let migrationVC = MigrationViewController()
    
    func isMigrationNecessary() -> Bool {
        //migration is necessary if the browser.db file exists.
        //file is deleted after migration.
        return FileManager.default.fileExists(atPath: fileUrlDB().path)
    }
    
    func startMigration(completion: @escaping () -> ()) {
        
        DispatchQueue(label: "background").async {
            
            let prefs = NSUserDefaultsPrefs(prefix: "profile")
            let db = BrowserDB(filename: "browser.db", files: self.files)
            let history = SQLiteHistory(db: db, prefs: prefs)
            
            self.startReadingAndWriting(history: history, totalCount: history.count()) { finished in
                if finished {
                    self.deleteDB(history: history, db: db)
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }
    
    func startReadingAndWriting(history: SQLiteHistory, totalCount: Int, completion: @escaping (Bool) -> Void) {
        
        let batch_size = 500
        
        func recursive(offset: Int) {
            history.getHistoryVisits(offset, limit: batch_size).upon({ (result) in
                let (visits, numberOfSitesFromDB) = self.processRawDataResults(result: result)
                self.write(visits: visits)
                if numberOfSitesFromDB < batch_size {
                    //finish
                    self.updateProgressBar(percent: 1.0)
                    completion(true)
                }
                else {
                    //update UI
                    self.updateProgressBar(percent: Float(offset) / Float(totalCount))
                    recursive(offset: offset + batch_size)
                }
            })
        }
        
        recursive(offset: 0)
    }
    
    func write(visits: [Visit]) {
        for visit in visits {
            if let url = visit.url.absoluteString, let date = visit.date {
                RealmStore.addVisitSync(url: url, title: visit.title, date: date)
            }
        }
    }
    
    func deleteDB(history: SQLiteHistory, db: BrowserDB) {
        db.forceClose()
        do {
            try FileManager.default.removeItem(at: fileUrlDB())
        }
        catch {
            debugPrint("error deleting db")
        }
    }
    
    //--------------------------------------------------
    
    func fileUrlDB() -> URL {
        let filename = "browser.db"
        let path = (try! files.getAndEnsureDirectory() as NSString).appendingPathComponent(filename)
        return URL.init(fileURLWithPath: path, isDirectory: false)
    }
    
    func updateProgressBar(percent: Float) {
        if percent >= 0.0 && percent <= 1.0 {
            DispatchQueue.main.async {
                self.migrationVC.progressBar.setProgress(percent, animated: true)
            }
        }
    }
    
    func processRawDataResults(result: Maybe<Cursor<Site>>) -> ([Visit], Int) {
        var historyResults: [Visit] = []
        var numberOfSitesFromDB = 0
        
        if let sites = result.successValue {
            numberOfSitesFromDB = sites.count
            for site in sites {
                if let domain = site, let url = NSURL(string: domain.url) {
                    let title = domain.title
                    var date:Date?  = nil
                    if let latestDate = domain.latestVisit?.date {
                        date =  Date.fromMicrosecondTimestamp(latestDate)
                    }
                    let d = Visit(title: title, url: url, date: date)
                    historyResults.append(d)
                }
            }
        }
        return (historyResults, numberOfSitesFromDB)
    }
}
