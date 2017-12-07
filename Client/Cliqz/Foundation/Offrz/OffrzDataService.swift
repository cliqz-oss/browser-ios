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
	let uid: String?
	let title: String?
	let description: String?
	let logoURL: String?
	let code: String?
	let url: String?
	let actionTitle: String?
}

class OffrzDataService {
	var lastOffrz = [Offrz]()

	private var validityStart: Date?
	private var validityEnd: Date?

	private static let APIURL = "https://offers-api.cliqz.com/api/v1/loadsubtriggers?parent_id=mobile-root&t_eng_ver=1"

	static let shared = OffrzDataService()

	func getMyOffrz(completionHandler: @escaping ([Offrz], Error?) -> Void) {
		self.loadData(successHandler: {
			print("Hello1")
			completionHandler(self.lastOffrz, nil)
		}, failureHandler: { (e) in
			completionHandler([], nil)
			print("Error : \(e)")
		})
	}

	func isLastOffrValid() -> Bool {
		return self.validityStart != nil && self.validityEnd != nil && !self.isExpiredOffr()
	}

	private func loadData(successHandler: @escaping () -> Void, failureHandler: @escaping (Error?) -> Void) {
		Alamofire.request(OffrzDataService.APIURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let data = response.result.value as? [Any] {
					self.lastOffrz = [Offrz]()
//					self.lastUpdateTime = Date()
					for o in data {
						if let offr = o as? [String: Any],
							let actions = offr["actions"] as? [Any] {

							for action in actions {
								if let actionType = action as? [Any], actionType.count > 1,
									let type = actionType[0] as? String,
									type == "$show_offer",
									let showOffer = actionType[1] as? [Any],
									showOffer.count > 1,
									let offrInfo = showOffer[1] as? [String: Any],
									let uiInfo = offrInfo["ui_info"] as? [String: Any],
									let details = uiInfo["template_data"] as? [String: Any] {
									var actionTitle: String?
									var url: String?
									if let callToAction = details["call_to_action"] as? [String: Any] {
										actionTitle = callToAction["text"] as? String
										url = callToAction["url"] as? String
									}
									self.lastOffrz.append(Offrz(uid: "1", title: details["title"] as? String, description: details["desc"] as? String, logoURL: details["logo_url"] as? String, code: details["code"] as? String, url: url, actionTitle: actionTitle))
								}
							}
						}
					}
					successHandler()
					return
				}
				failureHandler(nil) // TODO proper Error
			} else {
				failureHandler(response.error) // TODO proper Error
			}
		}
	}

	private func isExpiredOffr() -> Bool {
		let now =  Date()
		if let start = self.validityStart,
			let end = self.validityEnd {
			return start > now || end < now
		}
		return false
	}
}
