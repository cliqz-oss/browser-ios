//
//  CIDatePickerViewController.swift
//  Client
//
//  Created by Tim Palade on 5/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class CIDatePickerViewController: UIViewController {
    
    let datePicker: UIDatePicker = UIDatePicker()
    let cancelButton: UIButton = UIButton()
    let customButton: UIButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        datePicker.date = NSDate(timeIntervalSinceNow: 0)
        
        cancelButton.titleLabel?.text = "Cancel"
        cancelButton.backgroundColor = UIColor.whiteColor()
        cancelButton.layer.cornerRadius = 10
        cancelButton.clipsToBounds = true
        
        customButton.titleLabel?.text = "Customizable"
        customButton.backgroundColor = UIColor.whiteColor()
        customButton.layer.cornerRadius = 10
        customButton.clipsToBounds = true
        
        cancelButton.addTarget(self, action: #selector(cancelPressed), forControlEvents: .TouchUpInside)
        customButton.addTarget(self, action: #selector(customPressed), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(cancelButton)
        self.view.addSubview(customButton)
        self.view.addSubview(datePicker)
        
        cancelButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view)
            make.left.right.equalTo(self.view).inset(20)
            make.height.equalTo(80)
        }
        
        customButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.cancelButton.snp_top).inset(10)
            make.width.height.equalTo(self.cancelButton)
        }
        
        datePicker.snp_makeConstraints { (make) in
            make.bottom.equalTo(customButton.snp_top)
            make.left.right.equalTo(self.view)
        }
        
    }
    
    @objc
    func cancelPressed(sender: UIButton) {
        debugPrint("cancel pressed")
    }

    @objc
    func customPressed(sender: UIButton) {
        debugPrint("custom pressed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
