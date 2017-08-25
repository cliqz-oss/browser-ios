//
//  URLBarViewController.swift
//  Client
//
//  Created by Tim Palade on 8/1/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class URLBarViewController: UIViewController {
	
    var URLBarHeight: CGFloat = 64.0
    
	private var URLBar: CIURLBar = CIURLBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.addSubview(self.URLBar)

        setConstraints()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.URLBar.applyTheme(Theme.NormalMode)
	}

    func setConstraints() {

		self.URLBar.snp.makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.view)
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
//        NotificationCenter.default.removeObserver(self)
    }
    
}
