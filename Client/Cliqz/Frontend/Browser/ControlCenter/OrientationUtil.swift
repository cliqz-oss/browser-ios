//
//  OrientationUtil.swift
//  Client
//
//  Created by Tim Palade on 2/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum ScreenSizeClass{
    case compactWidthCompactHeight
    case compactWidthRegularHeight
    case regularWidthCompactHeight
    case regularWidthRegularHeight
    case unspecified
}

enum ControlPanelLayout{
    case portrait
    case landscapeRegularSize
    case landscapeCompactSize
}

protocol ControlCenterPanelDelegate: class {
    
    func closeControlCenter()
    func reloadCurrentPage()
    
}

class OrientationUtil: NSObject {
    
    class func isPortrait() -> Bool {
        if  UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            return true
        }
        return false
    }
    
    class func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    class func screenSizeClass() -> ScreenSizeClass {
        let traitCollection = UIScreen.main.traitCollection
        
        if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact){
            if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact)
            {
                return .compactWidthCompactHeight
            }
            else if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular){
                return .compactWidthRegularHeight
            }
        }
        else if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular){
            if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact)
            {
                return .regularWidthCompactHeight
            }
            else if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular){
                return .regularWidthRegularHeight
            }
        }
        
        return .unspecified
    }
    
    class func controlPanelLayout() -> ControlPanelLayout {
        
        let screenSizeClass = self.screenSizeClass()
        let screenHeight    = self.screenHeight()
        let iPhone6_landscape_height = CGFloat(375.0)
        //let iPhone6_landscape_width  = CGFloat(667.0)
        
        if self.isPortrait(){
            return .portrait
        }
        else if screenSizeClass != .unspecified {
            if screenSizeClass != .compactWidthCompactHeight || screenHeight >= iPhone6_landscape_height{
                return .landscapeRegularSize
            }
            else{
                return .landscapeCompactSize
            }
        }
        
        return .landscapeCompactSize
    }
}
