//
//  ProfileExtension.swift
//  Client
//
//  Created by Sahakyan on 3/31/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

private let TogglesPrefKey = "clearprivatedata.toggles"

extension Profile {
	
	fileprivate var toggles: [Bool] {
		get {
			if var savedToggles = self.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
				if savedToggles.count == 4 {
					savedToggles.insert(true, at:1)
				}
				return savedToggles
			}
			return [true, true, true, true, true]
		}
	}

	func clearPrivateData(_ tabManager: TabManager) {

        let clearables: [Clearable] = [
			HistoryClearable(profile: self),
			BookmarksClearable(profile: self),
			CacheClearable(tabManager: tabManager),
			CookiesClearable(tabManager: tabManager),
			SiteDataClearable(tabManager: tabManager),
		]
		
		for (i, c) in clearables.enumerated() {
			guard self.toggles[i] else {
				continue
			}
			c.clear()
		}
	}

}
