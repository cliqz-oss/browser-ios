//
//  UITextFieldExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 12/30/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

extension UITextField {
    
    func setLeftPading(_ pading: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: pading, height: self.frame.height));
        self.leftView = paddingView;
        self.leftViewMode = .always;
    }
}
