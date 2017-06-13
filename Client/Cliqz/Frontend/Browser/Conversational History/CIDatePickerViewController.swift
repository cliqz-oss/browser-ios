//
//  CIDatePickerViewController.swift
//  Client
//
//  Created by Tim Palade on 5/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol CIDatePickerDelegate: class {
    func customPressed(sender:UIButton, datePicker:CIDatePickerViewController)
    func cancelPressed(sender:UIButton, datePicker:CIDatePickerViewController)
}

class CIDatePickerViewController: UIViewController {
    
    var delegate: CIDatePickerDelegate? = nil
    let datePicker: UIDatePicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        
        let cancelButton: UIButton = UIButton(type: .Custom)
        let customButton: UIButton = UIButton(type: .Custom)
        
        datePicker.date = NSDate(timeIntervalSinceNow: 0)
        datePicker.backgroundColor = UIColor.whiteColor()
        datePicker.layer.cornerRadius = 10
        datePicker.clipsToBounds = true
        
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        cancelButton.backgroundColor = UIColor.whiteColor()
        cancelButton.layer.cornerRadius = 10
        cancelButton.clipsToBounds = true
        
        customButton.setTitle("Set Reminder", forState: .Normal)
        customButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        customButton.backgroundColor = UIColor.whiteColor()
        customButton.layer.cornerRadius = 10
        customButton.clipsToBounds = true
        
        cancelButton.addTarget(self, action: #selector(cancelPressed), forControlEvents: .TouchUpInside)
        customButton.addTarget(self, action: #selector(customPressed), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(cancelButton)
        self.view.addSubview(customButton)
        self.view.addSubview(datePicker)
        
        cancelButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(10)
            make.left.right.equalTo(self.view).inset(20)
            make.height.equalTo(80)
        }
        
        customButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(100)
            make.left.right.bottom.equalTo(self.view).inset(20)
            make.height.equalTo(80)
        }
        
        datePicker.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(200)
            make.left.right.equalTo(self.view).inset(20)
        }
        
    }
    
    @objc
    func cancelPressed(sender: UIButton) {
        debugPrint("cancel pressed")
        delegate?.cancelPressed(sender, datePicker: self)
    }

    @objc
    func customPressed(sender: UIButton) {
        debugPrint("custom pressed", self)
        delegate?.customPressed(sender, datePicker: self)
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
