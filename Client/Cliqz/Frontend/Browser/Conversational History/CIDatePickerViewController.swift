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
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        let cancelButton: UIButton = UIButton(type: .custom)
        let customButton: UIButton = UIButton(type: .custom)
        
        datePicker.date = Date(timeIntervalSinceNow: 0)
        datePicker.backgroundColor = UIColor.white
        datePicker.layer.cornerRadius = 10
        datePicker.clipsToBounds = true
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.red, for: .normal)
        cancelButton.backgroundColor = UIColor.white
        cancelButton.layer.cornerRadius = 10
        cancelButton.clipsToBounds = true
        
        customButton.setTitle("Set Reminder", for: .normal)
        customButton.setTitleColor(UIColor.blue, for: .normal)
        customButton.backgroundColor = UIColor.white
        customButton.layer.cornerRadius = 10
        customButton.clipsToBounds = true
        
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        customButton.addTarget(self, action: #selector(customPressed), for: .touchUpInside)
        
        self.view.addSubview(cancelButton)
        self.view.addSubview(customButton)
        self.view.addSubview(datePicker)
        
        cancelButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(10)
            make.left.right.equalTo(self.view).inset(20)
            make.height.equalTo(80)
        }
        
        customButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(100)
            make.left.right.bottom.equalTo(self.view).inset(20)
            make.height.equalTo(80)
        }
        
        datePicker.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(200)
            make.left.right.equalTo(self.view).inset(20)
        }
        
    }
    
    @objc
    func cancelPressed(sender: UIButton) {
        debugPrint("cancel pressed")
        delegate?.cancelPressed(sender: sender, datePicker: self)
    }

    @objc
    func customPressed(sender: UIButton) {
        debugPrint("custom pressed", self)
        delegate?.customPressed(sender: sender, datePicker: self)
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
