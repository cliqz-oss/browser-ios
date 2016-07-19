//
//  YoutubeDownloader.swift
//  Client
//
//  Created by Sahakyan on 7/14/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Photos
import JavaScriptCore
import Alamofire

class YoutubeDownloader {

	class func isYoutubeURL(url: NSURL) -> Bool {
		let pattern = "https?://(m\\.|www\\.)?youtube.+/watch\\?v=.*"
		return url.absoluteString.rangeOfString(pattern, options: .RegularExpressionSearch) != nil
	}

	class func downloadFromURL(url: String) {
		if var videoUrl = url.stringByRemovingPercentEncoding {
			videoUrl = videoUrl.stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet())!
			let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
			var localPath: NSURL = directoryURL.URLByAppendingPathComponent(NSDate().description)
			PHPhotoLibrary.requestAuthorization({ (authorizationStatus: PHAuthorizationStatus) -> Void in
				Alamofire.download(.GET, videoUrl, destination: {  (temporaryURL, response) -> NSURL in
					let pathComponent = NSDate().description + (response.suggestedFilename ?? "")
					localPath = directoryURL.URLByAppendingPathComponent(pathComponent)
					return localPath
				})
				.response {
					(request, response, _, error) in
					PHPhotoLibrary.sharedPhotoLibrary().performChanges({
						PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(localPath)}) { completed, error in
							if completed {
								// TODO: Postponed showing status info for the next release
								print("Video asset created")
							} else {
								// TODO: Postponed showing status info for the next release
								print(error)
							}
					}
					print(response)
				}
			})
		}
	}
	
}