//
//  ElementAtPoint.swift
//  Client
//
//  Created by Mahmoud Adam on 10/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class ElementAtPoint {
    
    static var javascript:String = {
        let path = NSBundle.mainBundle().pathForResource("ElementAtPoint", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        return source
    }()
    
    func windowSizeAndScrollOffset(webView: CliqzWebView) ->(CGSize, CGPoint)? {
        let response = webView.stringByEvaluatingJavaScriptFromString("JSON.stringify({ width: window.innerWidth, height: window.innerHeight, x: window.pageXOffset, y: window.pageYOffset })")
        do {
            guard let json = try NSJSONSerialization.JSONObjectWithData((response?.dataUsingEncoding(NSUTF8StringEncoding))!, options: [])
                as? [String:AnyObject] else { return nil }
            if let w = json["width"] as? CGFloat,
                let h = json["height"] as? CGFloat,
                let x = json["x"] as? CGFloat,
                let y = json["y"] as? CGFloat {
                return (CGSizeMake(w, h), CGPointMake(x, y))
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getHit(tapLocation: CGPoint) -> (url:String?, image:String?, urlTarget:String?)? {
        guard let webView = getCurrentWebView() else { return nil }

        var pt = webView.convertPoint(tapLocation, fromView: nil)
        
        let viewSize = webView.frame.size
        guard let (windowSize, _) = windowSizeAndScrollOffset(webView) else { return nil }
        
        let f = windowSize.width / viewSize.width;
        pt.x = pt.x * f;// + offset.x;
        pt.y = pt.y * f;// + offset.y;
        
        let result = webView.stringByEvaluatingJavaScriptFromString(ElementAtPoint.javascript + "(\(pt.x), \(pt.y))")
        //debugPrint("\(result ?? "no match")")
        
        guard let response = result where response.characters.count > "{}".characters.count else {
            return nil
        }
        
        do {
            guard let json = try NSJSONSerialization.JSONObjectWithData((response.dataUsingEncoding(NSUTF8StringEncoding))!, options: [])
                as? [String:AnyObject] else { return nil }
            func extract(name: String) -> String? {
                return(json[name] as? String)?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            }
            let image = extract("imagesrc")
            let url = extract("link")
            let target = extract("target")
            return (url:url, image:image, urlTarget:target)
        } catch {}
        return nil
    }
}
