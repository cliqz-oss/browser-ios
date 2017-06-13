//
//  YoutubeVideoDownloaderActivity.swift
//  Client
//
//  Created by Sahakyan on 7/15/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class YoutubeVideoDownloaderActivity: UIActivity {

	fileprivate let callback: () -> ()

	init(callback: @escaping () -> ()) {
		self.callback = callback
	}
	
	override var activityTitle : String? {
		return NSLocalizedString("Download youtube video", tableName: "Cliqz", comment: "Context menu item for opening a link in a new tab")

	}
    
    override var activityType: UIActivityType? {
        return UIActivityType("com.cliqz.youtubedownloader")
    }
	
	override var activityImage : UIImage? {
		return UIImage(named: "download")
	}
	
	override func perform() {
		callback()
		activityDidFinish(true)
	}
	
	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		return true
	}
}
