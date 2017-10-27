//
//  ShareViewController.swift
//  Cliqz
//
//  Created by Sahakyan on 10/24/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Storage
import Shared

class ShareViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
			if let item = item, error == nil {
				DispatchQueue.main.async {
					guard item.isShareable else {
						let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.cancel() })
						self.present(alert, animated: true, completion: nil)
						return
					}
					self.presentShareDialog(item)
				}
			} else {
				self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
			}
		})
	}

	private func presentShareDialog(_ item: ShareItem) {
		let alert = UIAlertController(title: NSLocalizedString("Open Link", tableName: "Cliqz", comment: "Action sheet title"), message: "", preferredStyle: .actionSheet)
		let open = UIAlertAction(title: NSLocalizedString("Open", tableName: "Cliqz", comment: "Open button titile"), style: .default) { _ in
			self.open(item.url)
		}
		let cancel = UIAlertAction(
			title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel button."),
			style: UIAlertActionStyle.cancel) { (action) in
				self.cancel()
				// Cliqz: log telemetry signal
		}
		alert.addAction(open)
		alert.addAction(cancel)
		self.present(alert, animated: true, completion: nil)
	}

	private func cancel() {
		self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
	}

	private func open(_ url: String) {
		if let u = URL(string: "cliqzbeta://?url=\(url.escape())") {
			self.extensionContext?.open(u, completionHandler: { (succeed) in
				let _ = self.openURL(u)
			})
			self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
		}
	}

	@objc func openURL(_ url: URL) -> Bool {
		var responder: UIResponder? = self
		while responder != nil {
			if let application = responder as? UIApplication {
				return application.perform(#selector(openURL(_:)), with: url) != nil
			}
			responder = responder?.next
		}
		return false
	}
}
