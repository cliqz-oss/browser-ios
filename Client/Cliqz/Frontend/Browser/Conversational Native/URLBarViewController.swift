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
    
    weak var search_loader: SearchLoader? = nil
    
    weak var externalDelegate: ActionDelegate? = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        URLBar.actionDelegate = self
        URLBar.stateDelegate = self
        URLBar.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    func setAutocompleteSuggestion(_ suggestion: String?) {
        URLBar.setAutocompleteSuggestion(suggestion)
    }
    
}

extension URLBarViewController: CIURLBarActionDelegate {
    
    func urlBarDidPressTabs(_ urlBar: CIURLBar) {
        
    }
    
    func urlBarDidPressReaderMode(_ urlBar: CIURLBar) {
        
    }
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func urlBarDidLongPressReaderMode(_ urlBar: CIURLBar) -> Bool {
        return false
    }
    
    func urlBarDidPressNewTab(_ urlBar: CIURLBar, button: UIButton) {
        
    }
    
    func urlBarDidPressAntitracking(_ urlBar: CIURLBar, trackersCount: Int, status: String) {
        
    }
    
    func urlBarDidLongPressLocation(_ urlBar: CIURLBar) {
        
    }
    
    func urlBarLocationAccessibilityActions(_ urlBar: CIURLBar) -> [UIAccessibilityCustomAction]? {
        return nil
    }
    
}

extension URLBarViewController: CIURLBarStateDelegate {
    
    func urlBarDidStartEditing(_ urlBar: CIURLBar) {
        
    }
    
    func urlBarDidFinishEditing(_ urlBar: CIURLBar) {
        
    }
    
    func urlBar(_ urlBar: CIURLBar, didEnterText text: String) {
        search_loader?.query = text
        externalDelegate?.action(action: Action(data: ["text": text], type: .searchTextChanged, context: .urlBarVC))
    }
    
    func urlBar(_ urlBar: CIURLBar, didSubmitText text: String) {
        
    }
    
    func urlBarDidClearSearchField(_ urlBar: CIURLBar, oldText: String?) {
        search_loader?.query = ""
        externalDelegate?.action(action: Action(data: nil, type: .searchTextCleared, context: .urlBarVC))
    }
}

extension URLBarViewController: CIURLBarDataSource {
    
    func urlBarDisplayTextForURL(_ url: URL?) -> String? {
        return nil
    }
}
