//
//  SearchHistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

class SearchHistoryViewController: HistoryPanel {

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
    }
    func prepareView() {
        self.title = NSLocalizedString("Search history", comment: "Search history title")
        
        // View
        self.view.backgroundColor = UIColor.whiteColor()

        // Navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 246.0/255.0, green: 90.0/255.0, blue: 42.0/255.0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        self.navigationItem.leftBarButtonItem = createUIBarButton("future", action: Selector("dismiss"))
    }
    
    //MARK: - Overriden methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        dismiss()
    }

    //MARK: - Private helpers
    private func createUIBarButton(imageName: String, action: Selector) -> UIBarButtonItem {
        
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
        button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 20, 20)

        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }

    //MARK: - Actions
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("past", "present"))
    }
}
