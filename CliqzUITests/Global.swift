//
//  Global.swift
//  Client
//
//  Created by Sahakyan on 2/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import XCTest
import KIF
import WebKit
import GCDWebServers
import Shared
@testable import Client
import Storage


extension XCTestCase {

	var tester: KIFUITestActor { return tester() }
	var system: KIFSystemTestActor { return system() }

	private func tester(file : String = #file, _ line : Int = #line) -> KIFUITestActor {
		return KIFUITestActor(inFile: file, atLine: line, delegate: self)
	}

	private func system(file : String = #file, _ line : Int = #line) -> KIFSystemTestActor {
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
    func waitForWebViewElementWithAccessibilityLabel(text: String) {
        runBlock { error in
            if (self.hasWebViewElementWithAccessibilityLabel(text)) {
                return KIFTestStepResult.Success
            }
            
            return KIFTestStepResult.Wait
        }
    }
    
    /**
     * Sets the text for a WKWebView input element with the given name.
     */
    func enterText(text: String, intoWebViewInputWithName inputName: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait
        
        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.enterTextIntoInputWithName(\"\(escaped)\", \"\(inputName)\");") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.Success : KIFTestStepResult.Failure
        }
        
        runBlock { error in
            if stepResult == KIFTestStepResult.Failure {
                error.memory = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Input element not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }
    
    /**
     * Clicks a WKWebView element with the given label.
     */
    func tapWebViewElementWithAccessibilityLabel(text: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait
        
        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.tapElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.Success : KIFTestStepResult.Failure
        }
        
        runBlock { error in
            if stepResult == KIFTestStepResult.Failure {
                error.memory = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Accessibility label not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }
    
    /**
     * Determines whether an element in the page exists.
     */
    func hasWebViewElementWithAccessibilityLabel(text: String) -> Bool {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait
        var found = false
        
        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.hasElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            found = success as? Bool ?? false
            stepResult = KIFTestStepResult.Success
        }
        
        runBlock { _ in return stepResult }
        
        return found
    }
    
    private func getWebViewWithKIFHelper() -> WKWebView {
        let webView = waitForViewWithAccessibilityLabel("Web content") as! WKWebView
        
        // Wait for the web view to stop loading.
        runBlock { _ in
            return webView.loading ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }
        
        var stepResult = KIFTestStepResult.Wait
        
        webView.evaluateJavaScript("typeof KIFHelper") { result, _ in
            if result as! String == "undefined" {
                let bundle = NSBundle(forClass: CliqzUITests.self)
                let path = bundle.pathForResource("KIFHelper", ofType: "js")!
                let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
                webView.evaluateJavaScript(source as String, completionHandler: nil)
            }
            stepResult = KIFTestStepResult.Success
        }
        
        runBlock { _ in return stepResult }
        
        return webView
    }

}
