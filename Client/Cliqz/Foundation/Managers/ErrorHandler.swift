//
//  ErrorHandler.swift
//  Client
//
//  Created by Sahakyan on 12/17/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation
import Crashlytics


enum CliqzErrorCode {
	case CliqzErrorCodeScriptsLoadingFailed
}

class ErrorHandler {

	internal class func handleError(errorCode: CliqzErrorCode, delegate: UIAlertViewDelegate, error: NSError) {
		switch (errorCode) {
		case .CliqzErrorCodeScriptsLoadingFailed:
			let title = NSLocalizedString("Sorry", tableName: "Cliqz", comment: "Error message title")
			let message = NSLocalizedString("Something went wrong, the script wasn't loaded.", tableName: "Cliqz", comment:"Error message when JS scripts for search can't be loaded")
			let cancel = NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel")
			let retry = NSLocalizedString("Retry", tableName: "Cliqz", comment: "Button label on Alert view ")
			showErrorMessage(title, message: message, cancelButtonTitle: cancel, otherButtonTitle: retry, delegate: delegate)
            
            let attirbutes = ["errorDescription": error.description]
            Answers.logCustomEventWithName("JavaScriptLoadError", customAttributes: attirbutes)
		}
	}
	
	private class func showErrorMessage(title: String, message: String, cancelButtonTitle: String, otherButtonTitle: String, delegate: UIAlertViewDelegate) {
		let alert = UIAlertView(title: title, message: message, delegate: delegate, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: otherButtonTitle)
		alert.show()
	}
}
