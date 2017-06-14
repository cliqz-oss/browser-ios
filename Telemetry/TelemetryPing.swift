/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
public func makeAdHocBookmarkMergePing(bundle: NSBundle, clientID: String, attempt: Int32, bufferRows: Int?, valid: [String: Bool]) -> JSON {
	let anyFailed = valid.reduce(false, combine: { $0 || $1.1 })
	
	var out: [String: AnyObject] = [
		"v": 1,
		"appV": AppInfo.appVersion,
		"build": bundle.objectForInfoDictionaryKey("BuildID") as? String ?? "unknown",
		"id": clientID,
		"attempt": Int(attempt),
		"success": !anyFailed,
		]
	
	if let bufferRows = bufferRows {
		out["rows"] = bufferRows
	}
	
	if anyFailed {
		valid.forEach { key, value in
			out[key] = value
		}
	}
	
	return JSON(out)
}
*/

/*
public func makeAdHocSyncStatusPing(_ bundle: Bundle, clientID: String, statusObject: [String: String]?, engineResults: [String: String]?, resultsFailure: MaybeErrorType?, clientCount: Int) -> JSON {
	let build = (bundle.object(forInfoDictionaryKey: "BuildID") ?? "unknown") as AnyObject
	let appVersion = (AppInfo.appVersion as AnyObject)
	let date = Date().description(with: nil) as AnyObject
	let status = (statusObject as AnyObject?) ?? JSON.null
	let engine = (engineResults as AnyObject?) ?? JSON.null
	let results = resultsFailure?.description ?? JSON.null
    let out: [String: AnyObject] = [
        "v": (1 as AnyObject),
        "appV": appVersion,
        "build": build,
        "id": clientID as AnyObject,
        "date": date,
        "clientCount": clientCount as AnyObject,
        "statusObject": status,
        "engineResults": engine,
        "resultsFailure": results
    ]

    return JSON(out as AnyObject)
}
*/
