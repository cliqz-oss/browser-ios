/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebImage

private let imageLock = NSLock()

extension UIImage {
    /// Despite docs that say otherwise, UIImage(data: NSData) isn't thread-safe (see bug 1223132).
    /// As a workaround, synchronize access to this initializer.
    /// This fix requires that you *always* use this over UIImage(data: NSData)!
    public static func imageFromDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage(data: data)
        imageLock.unlock()
        return image
    }

    /// Generates a UIImage from GIF data by calling out to SDWebImage. The latter in turn uses UIImage(data: NSData)
    /// in certain cases so we have to synchronize calls (see bug 1223132).
    public static func imageFromGIFDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage.sd_animatedGIF(with: data)
        imageLock.unlock()
        return image
    }

    public static func dataIsGIF(_ data: Data) -> Bool {
        guard data.count > 3 else {
            return false
        }

        // Look for "GIF" header to identify GIF images
        let header = [UInt8](data)
//        (data as Data).getBytes(&header, length: 3 * MemoryLayout<UInt8>.size)
        return header == [0x47, 0x49, 0x46]
    }

    public static func createWithColor(_ size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        color.setFill()
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    public func createScaled(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }

    public static func templateImageNamed(_ name: String) -> UIImage? {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }
    
    public class func UIImageWith(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    public func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
		
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let a = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
