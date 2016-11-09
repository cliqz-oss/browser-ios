//
//  YoutubeVideoDownloader.swift
//  Client
//
//  Created by Sahakyan on 7/14/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Photos
import JavaScriptCore
import Alamofire

class YoutubeVideoDownloader {

	class func isYoutubeURL(url: NSURL) -> Bool {
		let pattern = "https?://(m\\.|www\\.)?youtube.+/watch\\?v=.*"
		return url.absoluteString!.rangeOfString(pattern, options: .RegularExpressionSearch) != nil
	}

	class func downloadFromURL(url: String) {
		if var videoUrl = url.stringByRemovingPercentEncoding {
			videoUrl = videoUrl.stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet())!
			let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
			var localPath: NSURL = directoryURL.URLByAppendingPathComponent(NSDate().description)!
			
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus: PHAuthorizationStatus) -> Void in
                
                if authorizationStatus == .Authorized {
                    //TODO: Show status info for the user
                    print("[VedioDownloader] Download Started")
                    
                    Alamofire.download(.GET, videoUrl, destination: {  (temporaryURL, response) -> NSURL in
                        let pathComponent = NSDate().description + (response.suggestedFilename ?? "")
                        localPath = directoryURL.URLByAppendingPathComponent(pathComponent)!
                        return localPath
                    })
                        .response {
                            (request, response, _, error) in
                            if error != nil {
                                //TODO: Show status info for the user
                                print("[VedioDownloader] Download failed: \(error)")
                            } else {
                                YoutubeVideoDownloader.saveVideoToPhotoLibrary(localPath)
                            }
                    }
                }
				
			})
		}
	}
	
    private class func saveVideoToPhotoLibrary(localPath: NSURL) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(localPath)}) { completed, error in
                if completed {
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", "is_success", "true"))
                    //TODO: Show status info for the user
                    print("[VedioDownloader] Video asset created")
                } else {
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", "is_success", "false"))
                    //TODO: Show status info for the user
                    print("[VedioDownloader] Could not save video file on Phone: \(error)")
                }

        }
    }
    
}
