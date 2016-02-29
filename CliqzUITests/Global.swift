//
//  Global.swift
//  Client
//
//  Created by Sahakyan on 2/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

extension XCTestCase {
	
	var tester: KIFUITestActor { return tester() }
	var system: KIFSystemTestActor { return system() }
	
	private func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
		return KIFUITestActor(inFile: file, atLine: line, delegate: self)
	}

	private func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
		return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
	}
}

extension KIFUITestActor {
//	/// Looks for a view with the given accessibility hint.
//	func tryFindingViewWithAccessibilityHint(hint: String) -> Bool {
//		let element = UIApplication.sharedApplication().accessibilityElementMatchingBlock { element in
//			return element.accessibilityHint == hint
//		}
//		
//		return element != nil
//	}
//	
//	func waitForViewWithAccessibilityHint(hint: String) -> UIView? {
//		var view: UIView? = nil
//		autoreleasepool {
//			waitForAccessibilityElement(nil, view: &view, withElementMatchingPredicate: NSPredicate(format: "accessibilityHint = %@", hint), tappable: false)
//		}
//		return view
//	}
	
	func viewExistsWithLabel(label: String) -> Bool {
		do {
			try self.tryFindingViewWithAccessibilityLabel(label)
			return true
		} catch {
			return false
		}
	}
}