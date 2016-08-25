//
//  FavoritesViewController.swift
//  Client
//
//  Created by Sahakyan on 8/16/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

import WebKit
import Storage

protocol FavoritesDelegate: class {

	func didSelectURL(url: NSURL)

}

class FavoritesViewController: CliqzExtensionViewController {

	weak var delegate: FavoritesDelegate?

	override init(profile: Profile) {
		super.init(profile: profile)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func mainRequestURL() -> String {
		return NavigationExtension.favoritesURL
	}

	func getFavorites(callback: String?) {
		self.profile.bookmarks.getBookmarks().uponQueue(dispatch_get_main_queue()) { result in
			if let bookmarks = result.successValue {
				var favorites = [[String: AnyObject]]()
				for i in bookmarks {
					switch (i) {
					case let item as CliqzBookmarkItem:
						var bm = [String: AnyObject]()
						bm["title"] = item.title
						bm["url"] = item.url
						bm["timestamp"] = Double(item.bookmarkedDate)
						favorites.append(bm)
					default:
						print("Not a bookmark item")
					}
				}
				self.javaScriptBridge.callJSMethod(callback!, parameter: favorites, completionHandler: nil)
			}
		}
	}

}

extension FavoritesViewController {

	override func didSelectUrl(url: NSURL) {
		self.delegate?.didSelectURL(url)
	}

}