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

	func didSelectURL(_ url: URL)

}

class FavoritesViewController: CliqzExtensionViewController {

	weak var delegate: FavoritesDelegate?

	override init(profile: Profile) {
        super.init(profile: profile, viewType: "favorites")
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func mainRequestURL() -> String {
		return NavigationExtension.favoritesURL
	}

	func getFavorites(_ callback: String?) {

	}

}

extension FavoritesViewController {

	override func didSelectUrl(_ url: URL) {
		self.delegate?.didSelectURL(url)
	}

}
