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
    
    //work on some structure for clean animations.
    
    //To do. Think of how to compose animations. Read documentation
    //To solve this I can use a UIViewPropertyAnimator. 
    //Using the addAnimation method I can concatenate animations. 
    //To export my states as animations, the state functions should return function arrays of the form [() -> ()]
    //The order defines the order in which the animations are performed.
    //I can also attach to them a delay property, but this later.
    
    
    //The states of a component are dependent on the states of its subcomponents 
    //The total number of states a component can have is given by: Num_states_comp_1 * Num_states_comp_2 * ...
    //I am only interested in a subset of these cases, therefore I will define explicitly each component state I am interested in.
    //Since this depends on the states of the subcomponents I will define explicitly all the states for each subcomponent, together with the particularities of each state (e.g "constraints").
    //One state of the component will be the composition of states of subcomponents. 
    
    //I have 2 components now: The expandable view and the textField that changes height and width
    
    //I will start with the expandable view: 2 States: 1. Expanded 2. Contracted
    //I will define states as functions.
    
    //TO DO: Take the animation code into another module and write a small doc.
    
    private func expandableView_setExpanded() -> [Transition] {
        
        let transition = Transition(endState: {
            self.expandableView.snp.remakeConstraints { (make) in
                make.top.bottom.left.right.equalTo(self.view)
            }
            
            self.expandableView.layer.cornerRadius = 0
        })
        
        return [transition]
        
    }
    
    private func expandableView_setCollapsed() -> [Transition] {
        
        let transition = Transition(endState: {
            self.expandableView.snp.remakeConstraints { (make) in
                make.top.bottom.left.right.equalTo(self.textField)
            }
            
            self.expandableView.layer.cornerRadius = self.textFieldCornerRadius
        })
        
        return [transition]
    }
    
    //Now the textField. Again 2 states, with the same names, coincidentally.
    
    private func textField_setExpanded() -> [Transition] {
        
        let transition = Transition(endState: {
            self.textField.snp.remakeConstraints { (make) in
                make.center.equalTo(self.containerView)
                make.left.equalTo(self.containerView).offset(self.textFieldExpandedLeftInset)
                make.right.equalTo(self.containerView).inset(self.textFieldExpandedRightInset)
                make.height.equalTo(self.textFieldExpandedHeight)
            }
        })
        
        return [transition]
    }
    
    private func textField_setCollapsed() -> [Transition] {
        let transition = Transition(endState: {
            self.textField.snp.remakeConstraints { (make) in
                make.center.equalTo(self.containerView)
                make.left.equalTo(self.containerView).offset(self.textFieldCollapsedLeftInset)
                make.right.equalTo(self.containerView).inset(self.textFieldCollapsedRightInset)
                make.height.equalTo(self.textFieldCollapsedHeight)
            }
        })
        
        return [transition]
        
    }
    
    //Now the clear button
    
    private func clearButton_setVisible() -> [Transition] {
        
        let transition = Transition(endState: {
            self.clearButton.alpha = 1.0
            
            self.clearButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(self.containerView)
                make.right.equalTo(self.containerView)
                make.height.width.equalTo(40)
            }
        })
        
        return [transition]
        
    }
    
    private func clearButton_setInvisible() -> [Transition] {
        
        let transition = Transition(endState: {
            self.clearButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(self.containerView)
                make.right.equalTo(self.containerView).offset(10)
                make.height.width.equalTo(40)
            }
            
            self.clearButton.alpha = 0.0
        })
        
        return [transition]
    }
    
    //define component states as arrays of subcomponent functions. 
    //make sure the order is right.
    
    enum ComponentState {
        case expanded
        case collapsed
        case notSet
    }
    
    private var currentState: ComponentState = .notSet
    
    private let containerView = UIView()
    private let textField = UITextField()
    private let expandableView = UIView()
    private let clearButton = UIButton()
    
    private var currentComponentState: ComponentState = .collapsed
    
    private let textFieldCornerRadius    = CGFloat(5)
    private let textFieldCollapsedHeight = 26
    private let textFieldExpandedHeight  = 44
    
    private let textFieldCollapsedLeftInset  = 10
    private let textFieldCollapsedRightInset = 10
    private let textFieldExpandedLeftInset   = 10
    private let textFieldExpandedRightInset  = 40
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        buildStates()
        registerForNotifications()
        
        self.view.backgroundColor = UIColor.clear
        containerView.backgroundColor = UIColor.clear
        expandableView.backgroundColor = UIColor.white
        textField.backgroundColor = UIColor.white
        
        expandableView.layer.cornerRadius = textFieldCornerRadius
        
        textField.layer.cornerRadius = textFieldCornerRadius
        textField.placeholder = " Cliqz Search"
        textField.delegate    = self
        
        clearButton.setImage(UIImage.init(named: "find_close"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        
        self.containerView.addSubview(expandableView)
        self.containerView.addSubview(textField)
        self.containerView.addSubview(clearButton)
        self.view.addSubview(containerView)
        
        setConstraints()
    }
    
    
    
    func generateState(state: ComponentState) -> [Transition] {
        
        switch state {
        case .collapsed:
            return self.expandableView_setCollapsed() + self.textField_setCollapsed() + self.clearButton_setInvisible()
        case .expanded:
            return self.expandableView_setExpanded() + self.textField_setExpanded() + self.clearButton_setVisible()
        case .notSet:
            return []
        }
        
    }
    
    //To Do: Cache animators that have already been generated.
    func generateAnimators(state: ComponentState) -> [Animator] {
        
        return StateAnimator.generateAnimators(state: generateState(state: state), parentView: self.view)
    }
    
    func setConstraints() {
        
        self.containerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.view).inset(20)
        }
        
        //Initial state is the collapsed state
        for state in StateAnimator.generateStates(transitions: generateState(state: .collapsed)) {
            state()
        }
        
        currentState = .collapsed
    }
    
    func animateToState(state: ComponentState) {
        guard state != currentState else {
            return
        }
        
        StateAnimator.animate(animators: generateAnimators(state: state))
        
        currentState = state
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextChanged), name: Notification.Name.UITextFieldTextDidChange , object: nil)
    }
    
    @objc
    private func clearButtonPressed(_ sender: UIButton) {
        debugPrint("clear button pressed")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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

extension URLBarViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //
        animateToState(state: .expanded)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //
        animateToState(state: .collapsed)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldTextChanged(_ notification: Notification) {
        //debugPrint(notification)
    }
    
}
