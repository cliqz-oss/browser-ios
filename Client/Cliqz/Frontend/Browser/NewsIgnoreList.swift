//
//  NewsIgnoreList.swift
//  Client
//
//  Created by Tim Palade on 9/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//this has a delete rule. It should get rid of urls older than one day, because the assumption is that after one day they will not come back from the backend. So any time after 24 hours is fine for deletion. The easiest seems to be to delete all urls older than one day every time the app wakes up.

class NewsIgnoreList: PersistentList<String> {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    
}




