//
//  YoutubeDownloaderActivity.swift
//  Client
//
//  Created by Sahakyan on 7/15/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class YoutubeDownloaderActivity: UIActivity {

	private let callback: () -> ()

	init(callback: () -> ()) {
		self.callback = callback
	}
	
	override func activityTitle() -> String? {
		return NSLocalizedString("Download youtube video", tableName: "Cliqz", comment: "Context menu item for opening a link in a new tab")

	}
	
	override func activityImage() -> UIImage? {
		return UIImage(named: "download")
	}
	
	override func performActivity() {
		callback()
		activityDidFinish(true)
	}
	
	override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
		return true
	}
}