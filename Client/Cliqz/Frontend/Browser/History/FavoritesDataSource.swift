//
//  FavoritesDataSource.swift
//  Client
//
//  Created by Mahmoud Adam on 10/23/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

let FavoriteRemovedNotification = NSNotification.Name(rawValue: "favorites-removed")

class FavoritesDataSource: HistoryDataSource {

    override func reloadHistory(completion: (() -> Void )?) {
        HistoryModule.getFavorites(profile: profile) { [weak self] (historyEntries, error) in
            if error == nil,
                let orderedEntries = self?.groupByDate(historyEntries) {
                self?.sortedDetails = orderedEntries
                self?.delegate?.dataSourceWasUpdated()
                completion?()
            }
        }
    }
    
    override func deleteItem(at indexPath: IndexPath) {
        if let favoritesEntry = detail(indexPath: indexPath) as? HistoryUrlEntry {
            HistoryModule.remoteFavoritesEntry(profile: profile, url: favoritesEntry.url, callback: { [weak self] in
                DispatchQueue.main.async {
                    self?.reloadHistory(completion: nil)
                    NotificationCenter.default.post(name: FavoriteRemovedNotification, object: favoritesEntry.url)
                }
            })
        }
    }
}
