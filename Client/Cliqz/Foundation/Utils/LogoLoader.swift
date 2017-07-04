//
//  LogoLoader.swift
//  Client
//
//  Created by Sahakyan on 1/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Alamofire
import SnapKit
import WebImage
import SwiftyJSON

struct LogoInfo {
	var url: String?
	var color: String?
	var prefix: String?
	var fontSize: Int?
	var hostName: String?
}

class LogoLoader {

	private static let dbVersion = "1483980213630"

	private static var _logoDB: JSON?
	private static var logoDB: JSON? {
		get {
			if self._logoDB == nil {
				if let path = Bundle.main.path(forResource: "logo-database", ofType: "json", inDirectory: "Extension/build/mobile/search/core"),
				   let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) as Data {
					self._logoDB = JSON(jsonData)["domains"]
				}
			}
			return self._logoDB
		}
		set {
			self._logoDB = newValue
		}
	}

	class func loadLogo(_ url: String, completionBlock: @escaping (_ image: UIImage?, _ logoInfo: LogoInfo?,  _ error: Error?) -> Void) {
		let details = LogoLoader.fetchLogoDetails(url)
		if let u = details.url {
			LogoLoader.downloadImage(u, completed: { (image, error) in
				completionBlock(image, details, error)
			})
		} else {
			completionBlock(nil, details, nil)
		}
	}

	class func clearDB() {
		self.logoDB = nil
	}

	private class func fetchLogoDetails(_ url: String) -> LogoInfo {
		var logoDetails = LogoInfo()
		logoDetails.color = "000000"
		logoDetails.fontSize = 16
		if let urlDetails = URLParser.getURLDetails(url),
		   let hostName = urlDetails.name,
		   let details = self.logoDB?[hostName] {
			logoDetails.hostName = hostName
			logoDetails.prefix = hostName.substring(to: hostName.index(hostName.startIndex, offsetBy: 2)).capitalized
			if let list = details.array,
				list.count > 0 {
				for info in list {

					if info != JSON.null,
					   let r = info["r"].string,
					   isMatchingLogoRule(urlDetails, r) || info == list.last {

						if let doesLogoExist = info["l"].number, doesLogoExist == 1 {
							logoDetails.url = "https://cdn.cliqz.com/brands-database/database/\(self.dbVersion)/pngs/\(hostName)/\(r)_192.png"
						}
						logoDetails.color = info["b"].string
						if let txt = info["t"].string {
							logoDetails.prefix = txt
						}
					}
				}
			}
		}
		return logoDetails
	}

	private class func isMatchingLogoRule(_ urlDetails: URLDetails, _ rule: String) -> Bool {
		if let ix = urlDetails.host.range(of: urlDetails.name, options: .backwards, range: nil, locale: nil) {
			let newHost = urlDetails.host.replacingCharacters(in: ix, with: "$")
			return newHost == rule
		}
		return false
	}

	private class func downloadImage(_ url: String, completed: @escaping (_ image: UIImage?, _ error:  Error?) -> Void) {
		if let u = URL(string: url) {
			SDWebImageManager.shared().downloadImage(with: u, options:SDWebImageOptions.highPriority, progress: { (receivedSize, expectedSize) in },
													 completed: { (image, error, _, _, _) in completed(image, error)} as SDWebImageCompletionWithFinishedBlock)
		} else {
			completed(nil, nil)
		}
	}

}
