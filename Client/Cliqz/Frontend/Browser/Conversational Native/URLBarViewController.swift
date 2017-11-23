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
    
	fileprivate var URLBar: RefactoredURLBar = RefactoredURLBar()
    fileprivate let progressBar: ProgressBar = ProgressBar()

    weak var search_loader: SearchLoader? = nil
    
    enum ComponentState {
        case collapsedTransparent
        case collapsedBlue
        case expandedWhite
    }
    
    fileprivate var currentState: ComponentState = .collapsedTransparent
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        URLBar.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.addSubview(self.URLBar)
        self.view.addSubview(self.progressBar)
        setConstraints()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

    func setConstraints() {

		self.URLBar.snp.makeConstraints { (make) in
			make.left.top.right.bottom.equalTo(self.view)
		}
        
        self.progressBar.snp.makeConstraints { (make) in
            make.top.equalTo(self.URLBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(3)
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
        //URLBar.setAutocompleteSuggestion(suggestion)
        debugPrint(suggestion ?? "No suggestion")
    }
    
    func collapsedTransparent(text: String?) {
        currentState = .collapsedTransparent
        URLBar.backgroundColor = UIColor.clear
        URLBar.changeState(state: .collapsedSearch)
        URLBar.textField.text = text
        URLBar.textField.resignFirstResponder()
        progressBar.setProgress(progress: 0.0)
        progressBar.alpha = 0.0
    }
    
    func collapsedBlue(text: String?, isQuery: Bool = true) {
        currentState = .collapsedBlue
        URLBar.backgroundColor = UIConstants.CliqzThemeColor
        URLBar.changeState(state: isQuery ? .collapsedSearch : .collapsedBrowse)
        if isQuery {
            URLBar.textField.text = text
        }
        else {
            URLBar.domainLabel.text = processUrl(urlStr: text)
        }
        URLBar.textField.resignFirstResponder()
        if isQuery {
            progressBar.alpha = 0.0
            progressBar.setProgress(progress: 0.0)
        }
    }

    func expandedWhite(text: String?) {
        currentState = .expandedWhite
        URLBar.changeState(state: (text == "" || text == nil) ? .expandedEmpty : .expandedText)
        URLBar.textField.text = text
        if let t = text {
            search_loader?.query = t
        }
        progressBar.setProgress(progress: 0.0)
        progressBar.alpha = 0.0
    }
    
    func setProgress(progress: Float?) {
        
        guard currentState == .collapsedBlue else {
            return
        }
        
        guard let p = progress else {
            return
        }
        
        //I will refactor this. Use transitions
        UIView.animate(withDuration: 0.1, animations: {
            //self.progressBar.isHidden = false
            if p != 1.0 {
                self.progressBar.alpha = 1.0
            }
            
            self.progressBar.setProgress(progress: p)
            self.view.layoutIfNeeded()
        }, completion: { (finished) in
            if p == 1.0 {
                UIView.animate(withDuration: 0.8, animations: {
                    self.progressBar.alpha = 0.0
                    self.view.layoutIfNeeded()
                })
            }
        })
        
    }
    
    func processUrl(urlStr:String?) -> String? {
        guard let urlStr = urlStr else {
            return nil
        }
        
        guard let url = URL(string: urlStr) else {
            return "Invalid URL"
        }
        
        if let host = url.host {
            return host
        }
        
        return url.absoluteString
        
    }
}

//TO DO: Fill in the actions here.
extension URLBarViewController: RefactoredURLProtocol {
    func urlBackPressed() {
        StateManager.shared.handleAction(action: Action(type: .urlBackPressed))
    }
    
    func urlClearPressed() {
        StateManager.shared.handleAction(action: Action(type: .urlClearPressed))
    }
    
    func urlSearchPressed() {
        StateManager.shared.handleAction(action: Action(type: .urlSearchPressed))
    }
    
    func urlSearchTextChanged() {
        
        var data: [String: Any]? = nil
        
        if let t = URLBar.textField.text {
            data = ["text": t]
        }
        
        StateManager.shared.handleAction(action: Action(data: data, type: .urlSearchTextChanged))
    }
    
    func urlReturnPressed() {
        
        var data: [String: Any]? = nil
        
        if let t = URLBar.textField.text {
            data = ["url": t]
        }
        
        StateManager.shared.handleAction(action: Action(data: data, type: .urlSelected))
    }
}

extension URLBarViewController: CIURLBarActionDelegate {

	func urlBarDidPressBack(_ urlBar: CIURLBar) {
	}

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
//		externalDelegate?.action(action: Action(data: nil, type: .searchStart, context: .urlBarVC))
    }

    func urlBarDidFinishEditing(_ urlBar: CIURLBar) {
		
    }

	func urlBarDidCancelEditing(_ urlBar: CIURLBar) {
		//externalDelegate?.action(action: Action(data: nil, type: .urlBarCancelEditing, context: .urlBarVC))
	}

    func urlBar(_ urlBar: CIURLBar, didEnterText text: String) {
        search_loader?.query = text
        //externalDelegate?.action(action: Action(data: ["text": text], type: .searchTextChanged, context: .urlBarVC))
    }

    func urlBar(_ urlBar: CIURLBar, didSubmitText text: String) {
        //externalDelegate?.action(action: Action(data: ["url": text], type: .urlSelected, context: .urlBarVC))
        //bad
		urlBar.endEditing()
    }

    func urlBarDidClearSearchField(_ urlBar: CIURLBar, oldText: String?) {
        search_loader?.query = ""
        //externalDelegate?.action(action: Action(data: nil, type: .searchTextCleared, context: .urlBarVC))
    }
}

extension URLBarViewController: CIURLBarDataSource {
    
    func urlBarDisplayTextForURL(_ url: URL?) -> String? {
		// TODO: Test if this scenario is enough for URLBar display text in editing mode
		
        return url?.absoluteString
    }
}

final class ProgressBar: UIView {
    
    private let colorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpComponent()
        setConstraints()
        setStyling()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpComponent() {
        self.addSubview(colorView)
    }
    
    private func setStyling() {
        colorView.backgroundColor = UIColor(colorString: "930194")
    }
    
    private func setConstraints() {
        colorView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
    }

    func setProgress(progress: Float) {
        guard isProgressValid(progress: progress) else {
            return
        }
        
        colorView.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(progress)
        }
    }
    
    func isProgressValid(progress: Float) -> Bool {
        if progress >= 0.0 && progress <= 1.0 {
            return true
        }
        
        return false
    }
}
