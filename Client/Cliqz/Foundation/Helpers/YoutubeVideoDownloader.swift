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

                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    
                    let infoMessage = NSLocalizedString("The video is being downloaded.", tableName: "Cliqz", comment: "Toast message shown when youtube video download started")
                    FeedbackUI.showToastMessage(infoMessage, messageType: .Info)
                    
                    Alamofire.download(.GET, videoUrl, destination: {  (temporaryURL, response) -> NSURL in
                        let pathComponent = NSDate().description + (response.suggestedFilename ?? "")
                        localPath = directoryURL.URLByAppendingPathComponent(pathComponent)!
                        return localPath
                    })
                        .response {
                            (request, response, _, error) in
                            if error != nil {
                                
                                let errorMessage = NSLocalizedString("The download failed.", tableName: "Cliqz", comment: "Toast message shown when youtube video download faild")
                                FeedbackUI.showToastMessage(errorMessage, messageType: .Error)
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
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(localPath)
                creationRequest?.creationDate = NSDate()
            }) { completed, error in
                if completed {
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", "is_success", "true"))
                    
                    let infoMessage = NSLocalizedString("The download is complete. Open the Photos app to watch the video.", tableName: "Cliqz", comment: "Toast message shown when youtube video is Successfully downloaded")
                    FeedbackUI.showToastMessage(infoMessage, messageType: .Done)
                } else {
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", "is_success", "false"))
                    
                    let errorMessage = NSLocalizedString("The download failed.", tableName: "Cliqz", comment: "Toast message shown when youtube video download faild")
                    FeedbackUI.showToastMessage(errorMessage, messageType: .Error)
                }

                // Delete the local file after saving it to photos library
                YoutubeVideoDownloader.deleteLocalVideo(localPath)
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    private class func deleteLocalVideo(localPath: NSURL) {
        let fileManager = NSFileManager.defaultManager()
        do {
            if let path = localPath.path where fileManager.fileExistsAtPath(path) == true {
                try fileManager.removeItemAtPath(path)
            }
        } catch let error as NSError {
            debugPrint("[VedioDownloader] Could not delete local video at path \(localPath) because of the following error \(error)")
        }
    }
}
