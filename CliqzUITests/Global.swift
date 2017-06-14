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

	fileprivate func tester(_ file : String = #file, _ line : Int = #line) -> KIFUITestActor {
		return KIFUITestActor(inFile: file, atLine: line, delegate: self)
	}

	fileprivate func system(_ file : String = #file, _ line : Int = #line) -> KIFSystemTestActor {
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

	func viewExistsWithLabel(_ label: String) -> Bool {
		do {
			try self.tryFindingView(withAccessibilityLabel: label)
			return true
		} catch {
			return false
		}
	}
    func waitForWebViewElementWithAccessibilityLabel(_ text: String) {
        run { error in
            if (self.hasWebViewElementWithAccessibilityLabel(text)) {
                return KIFTestStepResult.success
            }
            
            return KIFTestStepResult.wait
        }
    }
    
    /**
     * Sets the text for a WKWebView input element with the given name.
     */
    func enterText(_ text: String, intoWebViewInputWithName inputName: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.wait
        
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavaScript("KIFHelper.enterTextIntoInputWithName(\"\(escaped)\", \"\(inputName)\");") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.success : KIFTestStepResult.failure
        }
        
        run { error in
            if stepResult == KIFTestStepResult.failure {
                error?.pointee = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Input element not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }
    
    /**
     * Clicks a WKWebView element with the given label.
     */
    func tapWebViewElementWithAccessibilityLabel(_ text: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.wait
        
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavaScript("KIFHelper.tapElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.success : KIFTestStepResult.failure
        }
        
        run { error in
            if stepResult == KIFTestStepResult.failure {
                error?.pointee = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Accessibility label not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }
    
    /**
     * Determines whether an element in the page exists.
     */
    func hasWebViewElementWithAccessibilityLabel(_ text: String) -> Bool {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.wait
        var found = false
        
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavaScript("KIFHelper.hasElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            found = success as? Bool ?? false
            stepResult = KIFTestStepResult.success
        }
        
        run { _ in return stepResult }
        
        return found
    }
    
    fileprivate func getWebViewWithKIFHelper() -> WKWebView {
        let webView = waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        
        // Wait for the web view to stop loading.
        run { _ in
            return webView.isLoading ? KIFTestStepResult.wait : KIFTestStepResult.success
        }
        
        var stepResult = KIFTestStepResult.wait
        
        webView.evaluateJavaScript("typeof KIFHelper") { result, _ in
            if result as! String == "undefined" {
                let bundle = Bundle(for: CliqzUITests.self)
                let path = bundle.path(forResource: "KIFHelper", ofType: "js")!
                let source = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
                webView.evaluateJavaScript(source as String, completionHandler: nil)
            }
            stepResult = KIFTestStepResult.success
        }
        
        run { _ in return stepResult }
        
        return webView
    }
    

}
//TO_DO Create a class that resets the browser to freshtab so that it is called before each test
// check Client>UItests>Global.swift>resetToAboutHome(tester:)
                                                              
//class BrowserUtils{
//    class func resetToFreshTab(tester: KIFTestActor){
//        do{
//        try tester.tryFindingTappableViewWithAccessibilityLabel}
//    
//    }
//}
