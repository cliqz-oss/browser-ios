//
//  RefactoredURLBar.swift
//  URLBarRefactoring
//
//  Created by Tim Palade on 9/15/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

import SnapKit

protocol RefactoredURLProtocol: class {
    func urlBackPressed()
    func urlClearPressed()
    func urlSearchPressed()
    func urlSearchTextChanged()
    func urlReturnPressed()
}

class RefactoredURLBar: UIView {
    
    
    //To do:
    //1. Add backButton - Add selector
    //2. Add clear button - Add selector
    //3. Make interface for query and url. Setting the query and the url should be straight forward.
    //4. Integrate Autocompletion
    
    
    //Define actions
    
    let textField = UITextField()
    let textFieldBGView = UIView() //this expands
    let textFieldContainer = UIView() //this is only to help me position the textfield
    let domainLabel = UILabel()

    let backButton = UIButton()
    let clearButton = UIButton()

    let textFieldCornerRadius: CGFloat = 5.0
    let textFieldCollapsedHeight: CGFloat = 30.0
    let textFieldExpandedHeight: CGFloat = 44.0

    enum State {
        case expandedEmpty
        case expandedText
        case collapsedSearch
        case collapsedBrowse
    }
    
	var currentState: State = .collapsedSearch {
		didSet {
			switch(currentState) {
				case .expandedEmpty, .expandedText, .collapsedBrowse:
					UIApplication.shared.statusBarStyle = .default
				case .collapsedSearch:
					UIApplication.shared.statusBarStyle = .lightContent
			}
		}
	}

    weak var delegate: RefactoredURLProtocol? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
		UIApplication.shared.statusBarStyle = .lightContent

        //Initial state
        setUpComponent()
        setStyling()
        setConstraints()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUpComponent() {
        textFieldBGView.addSubview(domainLabel)
        addSubview(textFieldContainer)
        addSubview(textFieldBGView)
        addSubview(textField)
        addSubview(backButton)
        addSubview(clearButton)
        
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldTextChanged), for: UIControlEvents.editingChanged)
        
        textField.placeholder = "  Search"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = .webSearch
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.returnKeyType = UIReturnKeyType.go
        textField.enablesReturnKeyAutomatically = true
        textField.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        textField.accessibilityIdentifier = "address"
        textField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        textFieldBGView.addGestureRecognizer(tap)
        
        backButton.setImage(UIImage.templateImageNamed("urlExpand"), for: .normal)
        clearButton.setImage(UIImage.templateImageNamed("cliqzClear"), for: .normal)
        
        backButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearPressed), for: .touchUpInside)
    }
    
    func setStyling() {
        textFieldContainer.backgroundColor = UIColor.clear
        textField.backgroundColor = UIColor.white
        textFieldBGView.backgroundColor = UIColor.white
        
        self.backgroundColor = .clear
    }
    
    func setConstraints() {
        
        textFieldContainer.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        
        backButton.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview()
            make.right.equalTo(self.snp.left)
            make.width.height.equalTo(44.0)
        })
        
        clearButton.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(self.snp.right)
            make.width.height.equalTo(44.0)
        })
        
        for state in StateGenerator.generateStates(transitions: generateState(state: currentState)) {
            state()
        }
    }
}

//handle tap + backButton + clearButton
extension RefactoredURLBar {
    @objc
    func tapped() {
        //this will be routed to the StateManager through textFieldShouldBeginEditing
        textField.becomeFirstResponder()
    }
    
    @objc
    func backPressed(button: UIButton) {
        delegate?.urlBackPressed()
    }
    
    @objc
    func clearPressed(button: UIButton) {
        delegate?.urlClearPressed()
    }
    
    @objc
    func textFieldTextChanged(textField: UITextField) {
        delegate?.urlSearchTextChanged()
    }
}

extension RefactoredURLBar: UITextFieldDelegate {
    
    //Attention -- all actions have to be routed through the State Manager. That is where decisions about the state are made.
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.urlSearchPressed()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.urlReturnPressed()
        return true
    }
}

//state
extension RefactoredURLBar {
    
    func changeState(state: State, text: String? = nil) {
        guard currentState != state else {
            return
        }
        
        currentState = state
        
        animateToState(state: currentState)
    }
    
    fileprivate func animateToState(state: State) {
        StateAnimator.animate(animators: generateAnimators(state: state))
    }
    
    fileprivate func generateAnimators(state: State) -> [Animator] {
        return StateAnimator.generateAnimators(state: generateState(state: state), parentView: self)
    }
    
    fileprivate func generateState(state: State) -> [Transition] {
        switch state {
        case .expandedEmpty:
            return self.backButtonVisible() + self.clearButtonInvisible() + self.textFieldExpanded() + self.textFieldBGViewExpanded() + self.domainLabelInvisible()
        case .expandedText:
            return self.backButtonVisible() + self.clearButtonVisible() + self.textFieldExpanded() + self.textFieldBGViewExpanded() + self.domainLabelInvisible()
        case .collapsedSearch:
            return self.backButtonInvisible() + self.clearButtonInvisible() + self.textFieldCollapsedSearch() + self.textFieldBGViewCollapsedSearch() + self.domainLabelInvisible()
        case .collapsedBrowse:
            return self.backButtonInvisible() + self.clearButtonInvisible() + self.textFieldCollapsedBrowse() + self.textFieldBGViewCollapsedBrowse() + self.domainLabelVisible()
        }
    }
    
    func textFieldExpanded() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textField.isHidden = false
            
            self.textField.alpha = 1.0
            
            self.textField.layer.cornerRadius = 0.0
            
            self.textField.snp.remakeConstraints({ (make) in
                make.centerY.equalTo(self.textFieldContainer)
                make.left.equalTo(self.backButton.snp.right)
                make.right.equalTo(self.clearButton.snp.left)
                make.height.equalTo(self.textFieldExpandedHeight)
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func textFieldCollapsedSearch() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textField.isHidden = false
            
            self.textField.alpha = 1.0
            
            self.textField.layer.cornerRadius = self.textFieldCornerRadius
            
            self.textField.snp.remakeConstraints({ (make) in
                make.centerY.equalTo(self.textFieldContainer)
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().inset(10)
                make.height.equalTo(self.textFieldCollapsedHeight)
            })
            
        } ,animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func textFieldCollapsedBrowse() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textField.isHidden = true
            
            self.textField.alpha = 0.0
            
            self.textField.layer.cornerRadius = self.textFieldCornerRadius
            
            self.textField.snp.remakeConstraints({ (make) in
                make.centerY.equalTo(self.textFieldContainer)
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().inset(10)
                make.height.equalTo(self.textFieldCollapsedHeight)

            })
            
        }, animationDetails: AnimationDetails(duration: 0.1, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func textFieldBGViewExpanded() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textFieldBGView.layer.cornerRadius = 0.0
            
            self.textFieldBGView.snp.remakeConstraints({ (make) in
                make.top.right.bottom.left.equalToSuperview()
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func textFieldBGViewCollapsedSearch() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textFieldBGView.layer.cornerRadius = self.textFieldCornerRadius
            
            self.textFieldBGView.snp.remakeConstraints({ (make) in
                make.top.right.bottom.left.equalTo(self.textField)
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func textFieldBGViewCollapsedBrowse() -> [Transition] {
        let transition = Transition(endState: {
            
            self.textFieldBGView.layer.cornerRadius = self.textFieldCornerRadius
            
            self.textFieldBGView.snp.remakeConstraints({ (make) in
                make.top.right.bottom.left.equalTo(self.textField)
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }

    func domainLabelVisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.domainLabel.isHidden = false
            
            self.domainLabel.alpha = 1.0
            
            self.domainLabel.snp.remakeConstraints({ (make) in
                make.center.equalToSuperview()
            })
            
        } , animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func domainLabelInvisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.domainLabel.isHidden = true
            
            self.domainLabel.alpha = 0.0
            
            self.domainLabel.snp.remakeConstraints({ (make) in
                make.center.equalToSuperview()
            })
        }, animationDetails:AnimationDetails(duration: 0.1, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func backButtonVisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.backButton.alpha = 1.0
            
            self.backButton.snp.remakeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.width.height.equalTo(44.0)
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func backButtonInvisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.backButton.alpha = 0.0
        }, afterTransition: {
            self.backButton.snp.remakeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.right.equalTo(self.snp.left)
                make.width.height.equalTo(44.0)
            })
            
            self.layoutIfNeeded()
        } ,animationDetails:AnimationDetails(duration: 0.1, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func clearButtonVisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.clearButton.alpha = 1.0
            
            self.clearButton.snp.remakeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.right.equalToSuperview()
                make.width.height.equalTo(44.0)
            })
            
        }, animationDetails:AnimationDetails(duration: 0.2, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    func clearButtonInvisible() -> [Transition] {
        let transition = Transition(endState: {
            
            self.clearButton.alpha = 0.0
        }, afterTransition: {
            self.clearButton.snp.remakeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalTo(self.snp.right)
                make.width.height.equalTo(44.0)
            })
            
            self.layoutIfNeeded()
            
        } ,animationDetails:AnimationDetails(duration: 0.1, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
}
