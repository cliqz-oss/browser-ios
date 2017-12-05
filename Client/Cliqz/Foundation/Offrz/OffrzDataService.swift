//
//  OffrzAPI.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Alamofire

struct Offrz {
	let title: String?
	let description: String?
	let logoURL: String?
	let code: String?
}

class OffrzDataService {
	var lastOffrz = [Offrz]()

	private var lastUpdateTime: Date?
	private static let APIURL = "https://offers-api.cliqz.com/api/v1/loadsubtriggers?parent_id=mobile-root&t_eng_ver=1"

	static let shared = OffrzDataService()

	func getMyOffrz(completionHandler: @escaping ([Offrz], Error?) -> Void) {
		if self.isDataUptoDate() {
			completionHandler(self.lastOffrz, nil)
		} else {
			self.loadData(successHandler: {
				print("Hello1")
			}, failureHandler: { (e) in
				print("Hello : \(e)")
			})
		}
	}

	private func loadData(successHandler: @escaping () -> Void, failureHandler: @escaping (Error) -> Void) {
		Alamofire.request(OffrzDataService.APIURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let data = response.result.value as? [Any] {
					self.lastOffrz = [Offrz]()
					self.lastUpdateTime = Date()
					for o in data {
						if let offr = o as? [String: Any],
						let actions = offr["actions"] as? [String: Any],
						let level1 = actions["1"] as? [String: Any],
						let level2 = level1["1"] as? [String: Any],
						let level3 = level2["1"] as? [String: Any],
						let info = level3["ui_info"] as? [String: Any],
						let details = info["template_data"] as? [String: Any] {
							self.lastOffrz.append(Offrz(title: details["title"] as? String, description: details["desc"] as? String, logoURL: details["logo_url"] as? String, code: details["code"] as? String))
						}
					}
				}
			} else {
				
			}
		}
	}

	func isDataUptoDate() -> Bool {
		// TODO: complete the logic
		return self.lastUpdateTime != nil
	}
}
