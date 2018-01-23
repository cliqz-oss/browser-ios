//
//  CliqzBackgroundImage.swift
//  Client
//
//  Created by Sahakyan on 1/15/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation

extension UIImage {

	class func fullBackgroundImage() -> UIImage? {
		if UIDevice.current.orientation == .portrait {
			if UIDevice.current.isiPhoneXDevice() {
				return UIImage(named: "normalModeBgImage")
			}
			if UIDevice.current.isiPad() {
				return UIImage(named: "normalModeiPadBgImage")
			}
			return UIImage(named: "normalModeBgImage")
		}
		if UIDevice.current.isiPhoneXDevice() {
			return UIImage(named: "normalModeiPhoneXLandscapeBgImage")
		}
		if UIDevice.current.isiPad() {
			return UIImage(named: "normalModeiPadLandscapeBgImage")
		}
		return UIImage(named: "normalModeLandscapeBgImage")
	}

	class func freshtabBackgroundImage() -> UIImage? {
		if UIDevice.current.orientation == .portrait {
			if UIDevice.current.isiPhoneXDevice() {
				return UIImage(named: "normalModeiPhoneXFreshtabBgImage")
			}
			if UIDevice.current.isiPad() {
				return UIImage(named: "normalModeiPadFreshtabBgImage")
			}
			return UIImage(named: "normalModeFreshtabBgImage")
		}
		if UIDevice.current.isiPhoneXDevice() {
			return UIImage(named: "normalModeiPhoneXFreshtabLandscapeBgImage")
		}
		if UIDevice.current.isiPad() {
			return UIImage(named: "normalModeiPadFreshtabLandscapeBgImage")
		}
		return UIImage(named: "normalModeFreshtabLandscapeBgImage")
	}

}
