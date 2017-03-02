//
//  OrientationUtil.swift
//  Client
//
//  Created by Tim Palade on 2/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum ScreenSizeClass{
    case CompactWidthCompactHeight
    case CompactWidthRegularHeight
    case RegularWidthCompactHeight
    case RegularWidthRegularHeight
    case Unspecified
}

enum ControlPanelLayout{
    case Portrait
    case LandscapeRegularSize
    case LandscapeCompactSize
}

protocol ControlCenterPanelDelegate: class {
    
    func closeControlCenter()
    func reloadCurrentPage()
    
}

class OrientationUtil: NSObject {
    
    class func isPortrait() -> Bool {
        if  UIScreen.mainScreen().bounds.size.height > UIScreen.mainScreen().bounds.size.width {
            return true
        }
        return false
    }
    
    class func screenHeight() -> CGFloat {
        return UIScreen.mainScreen().bounds.size.height
    }
    
    class func screenSizeClass() -> ScreenSizeClass {
        let traitCollection = UIScreen.mainScreen().traitCollection
        
        if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact){
            if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact)
            {
                return .CompactWidthCompactHeight
            }
            else if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular){
                return .CompactWidthRegularHeight
            }
        }
        else if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Regular){
            if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact)
            {
                return .RegularWidthCompactHeight
            }
            else if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular){
                return .RegularWidthRegularHeight
            }
        }
        
        return .Unspecified
    }
    
    class func controlPanelLayout() -> ControlPanelLayout {
        
        let screenSizeClass = self.screenSizeClass()
        let screenHeight    = self.screenHeight()
        let iPhone6_landscape_height = CGFloat(375.0)
        //let iPhone6_landscape_width  = CGFloat(667.0)
        
        if self.isPortrait(){
            return .Portrait
        }
        else if screenSizeClass != .Unspecified {
            if screenSizeClass != .CompactWidthCompactHeight || screenHeight >= iPhone6_landscape_height{
                return .LandscapeRegularSize
            }
            else{
                return .LandscapeCompactSize
            }
        }
        
        return .LandscapeCompactSize
    }
}
