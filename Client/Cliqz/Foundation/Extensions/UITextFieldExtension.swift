//
//  UITextFieldExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 12/30/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

extension UITextField {
    
    func setLeftPading(pading: CGFloat) {
        let paddingView = UIView(frame: CGRectMake(0, 0, pading, self.frame.height));
        self.leftView = paddingView;
        self.leftViewMode = .Always;
    }
}
