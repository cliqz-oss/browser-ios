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

	class func isYoutubeURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
		let pattern = "https?://(m\\.|www\\.)?youtube.+/watch\\?v=.*"
		return url.absoluteString.range(of: pattern, options: .regularExpression) != nil
	}

    class func downloadFromURL(_ url: String, viaConnect: Bool = false) {
		if var videoUrl = url.removingPercentEncoding {
			videoUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
			let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
			var localPath: URL = directoryURL.appendingPathComponent(Date().description)
			
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus: PHAuthorizationStatus) -> Void in
                
                if authorizationStatus == .authorized {

                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    
                    let infoMessage = NSLocalizedString("The video is being downloaded.", tableName: "Cliqz", comment: "Toast message shown when youtube video download started")
                    FeedbackUI.showToastMessage(infoMessage, messageType: .info)
                    
                    // Telemetry
                    if viaConnect {
                        TelemetryLogger.sharedInstance.logEvent(.Connect("show", ["view": "message_download_start"]))
                    }
                    
                    Alamofire.download(videoUrl, to: {  (temporaryURL, response) -> (destinationURL: URL, options: Alamofire.DownloadRequest.DownloadOptions) in
                        let pathComponent = Date().description + (response.suggestedFilename ?? "")
                        localPath = directoryURL.appendingPathComponent(pathComponent)
                        return (localPath, [.removePreviousFile])
                    })
                        .response {
                            response in
                            if response.error != nil {
                                
                                let errorMessage = NSLocalizedString("The download failed.", tableName: "Cliqz", comment: "Toast message shown when youtube video download faild")
                                FeedbackUI.showToastMessage(errorMessage, messageType: .error)
                                // Telemetry
                                if viaConnect {
                                    TelemetryLogger.sharedInstance.logEvent(.Connect("download", ["is_success": false]))
                                } else {
                                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", ["is_success": false]))
                                }
                            } else {
                                YoutubeVideoDownloader.saveVideoToPhotoLibrary(localPath, viaConnect: viaConnect)
                            }
                    }
                }
				
			})
		}
	}
	
    fileprivate class func saveVideoToPhotoLibrary(_ localPath: URL, viaConnect: Bool = false) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localPath)
            creationRequest?.creationDate = Date()
        }) { completed, error in
            if completed {
                let infoMessage = NSLocalizedString("The download is complete. Open the Photos app to watch the video.", tableName: "Cliqz", comment: "Toast message shown when youtube video is Successfully downloaded")
                FeedbackUI.showToastMessage(infoMessage, messageType: .done)
            } else {
                let errorMessage = NSLocalizedString("The download failed.", tableName: "Cliqz", comment: "Toast message shown when youtube video download faild")
                FeedbackUI.showToastMessage(errorMessage, messageType: .error)
            }

            // Delete the local file after saving it to photos library
            YoutubeVideoDownloader.deleteLocalVideo(localPath)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Telemetry
            if viaConnect {
                TelemetryLogger.sharedInstance.logEvent(.Connect("download", ["is_success": completed]))
            } else {
                TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("download", ["is_success": completed]))
            }

        }
    }
    
    fileprivate class func deleteLocalVideo(_ localPath: URL) {
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: localPath.path) {
                try fileManager.removeItem(atPath: localPath.path)
            }
        } catch let error as NSError {
            debugPrint("[VedioDownloader] Could not delete local video at path \(localPath) because of the following error \(error)")
        }
    }
}
