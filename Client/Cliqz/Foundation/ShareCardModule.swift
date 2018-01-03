//
//  ShareCardModule.swift
//  Client
//
//  Created by Tim Palade on 1/3/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import React

@objc(ShareCardModule)
open class ShareCardModule: RCTEventEmitter {
    @objc(share:success:error:)
    func share(data: NSDictionary, success: RCTResponseErrorBlock, error: RCTResponseSenderBlock) {
        debugPrint("share")
        if let image_data_str = data["url"] as? String {
            if let image_data = Data.init(base64Encoded: image_data_str, options: .ignoreUnknownCharacters) {
                if let title = data["title"] as? String {
                    self.presentShareCardActivityViewController(title, data: image_data)
                }
            }
        }
    }
    
    
    func presentShareCardActivityViewController(_ title:String, data: Data) {
        
        guard let appDel = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let fileName = String(Date.getCurrentMillis())
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).png")
        do {
            try data.write(to: tempFile)
            var activityItems = [AnyObject]()
            activityItems.append(TitleActivityItemProvider(title: title, activitiesToIgnore: [UIActivityType.init("net.whatsapp.WhatsApp.ShareExtension")]))
            activityItems.append(tempFile as AnyObject)
            
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            //activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.excludedActivityTypes = [.assignToContact]
            
            activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                if let target = activityType?.rawValue {
                    TelemetryLogger.sharedInstance.logEvent(.ContextMenu(target, "card_sharing", ["is_success": completed]))
                }
                try? FileManager.default.removeItem(at: tempFile)
            }
            
            appDel.presentContollerOnTop(controller: activityViewController)
            //present(activityViewController, animated: true, completion: nil)
        } catch _ {
            
        }
    }
}
