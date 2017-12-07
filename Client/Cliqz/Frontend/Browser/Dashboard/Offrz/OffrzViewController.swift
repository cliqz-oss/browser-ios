//
//  OffrzViewController.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class OffrzViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		OffrzDataService.shared.getMyOffrz { (offrz, error) in
			print("Hello ---- \(offrz)")
		}
	}
}
