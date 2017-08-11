//
//  ExpandableView.swift
//  DashboardComponent
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

protocol ExpandableViewProtocol {
    func maxNumCells() -> Int
    func minNumCells() -> Int
    func title(indexPath: IndexPath) -> String
    func url(indexPath: IndexPath) -> String
    func picture(indexPath: IndexPath) -> UIImage?
    func cellPressed(indexPath: IndexPath)
}

protocol ExpandableViewDelegate {
    func heightChanged(newHeight: CGFloat, oldHeight: CGFloat)
}

final class ExpandableView: UITableView {
    
    enum ComponentState {
        case collapsed
        case expanded
    }
    
    var currentHeight: CGFloat = 0
    var currentState: ComponentState = .collapsed
    var customDataSource: ExpandableViewProtocol? = nil
    var customDelegate: ExpandableViewDelegate? = nil
    
    let headerHeight: CGFloat = 30.0
    let cellHeight: CGFloat = 68.0
    
    let cellIdentifier = "ExpandViewCell"
    
    var headerTitleText: String = ""

    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), style: UITableViewStyle = .plain, customDataSource: ExpandableViewProtocol) {
        super.init(frame: frame, style: style)
        self.customDataSource = customDataSource
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    func setUpComponent() {
        currentHeight = initialHeight()
        self.dataSource = self
        self.delegate = self
        self.register(ExpandableViewCell.self , forCellReuseIdentifier: cellIdentifier)
        self.isScrollEnabled = false
    }
    
    func setStyling() {
        self.layer.cornerRadius = 10.0
    }
    
    func setConstraints() {
        
    }
    
    func changeState(state: ComponentState) {
        guard state != currentState else {
            return
        }
        
        let newHeight = height(state: state)
        
        changeHeight(height: newHeight)
        
        currentHeight = newHeight
        currentState = state
        
        self.reloadData()
    }
    
    func commuteState() {
        if currentState == .collapsed {
            changeState(state: .expanded)
        }
        else {
            changeState(state: .collapsed)
        }
    }
    
    func numCells(state: ComponentState) -> Int {
        
        if state == .collapsed {
            return customDataSource?.minNumCells() ?? 0
        }
        else if state == .expanded {
            return customDataSource?.maxNumCells() ?? 0
        }
        
        return 0
    }
    
    func initialHeight() -> CGFloat {
        return height(state: .collapsed)
    }
    
    func height(state: ComponentState) -> CGFloat {
        return CGFloat(numCells(state: state)) * cellHeight + headerHeight
    }
    
    func changeHeight(height: CGFloat) {
        self.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        
        self.customDelegate?.heightChanged(newHeight: height, oldHeight: currentHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ExpandableView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.customDataSource?.cellPressed(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ExpandableView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentState == .expanded {
            return customDataSource?.maxNumCells() ?? 0
        }
        
        return customDataSource?.minNumCells() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ExpandableViewCell
        cell.titleLabel.text = customDataSource?.title(indexPath: indexPath)
        cell.URLLabel.text = customDataSource?.url(indexPath: indexPath)
        cell.logoImageView.image = customDataSource?.picture(indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ExpandableViewHeader(dataSource: self, state: currentState)
        header.delegate = self
        return header
    }
    
}

extension ExpandableView: ExpandableViewHeaderDelegate {
    func showMorePressed() {
        commuteState()
    }
}

extension ExpandableView: ExpandableViewHeaderDataSource {
    func headerTitle() -> String {
        return self.headerTitleText
    }
}

protocol ExpandableViewHeaderDataSource {
    func headerTitle() -> String
}


protocol ExpandableViewHeaderDelegate {
    func showMorePressed()
}


final class ExpandableViewHeader: UIView {
    
    let l = UILabel()
    let btn = UIButton()
    
    let buttonTitle_more = "More"
    let buttonTitle_less = "Less"
    
    var delegate: ExpandableViewHeaderDelegate? = nil
    var dataSource: ExpandableViewHeaderDataSource? = nil
    
    var parentState: ExpandableView.ComponentState? = nil
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), dataSource: ExpandableViewHeaderDataSource, state: ExpandableView.ComponentState) {
        super.init(frame: frame)
        self.dataSource = dataSource
        self.parentState = state
        setUpComponents()
        setStyling()
        setConstraints()
    }
    
    private func setUpComponents() {
        self.addSubview(l)
        self.addSubview(btn)
        
        btn.addTarget(self, action: #selector(showMorePressed), for: .touchUpInside)
        l.text = dataSource?.headerTitle()
        
        if parentState == .collapsed {
            btn.setTitle(buttonTitle_more, for: .normal)
        }
        else {
            btn.setTitle(buttonTitle_less, for: .normal)
        }
    }
    
    private func setStyling() {
        
        self.backgroundColor = UIColor.black
        
        l.textColor = UIColor.white
        l.font = UIFont.systemFont(ofSize: 13)
        
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        btn.titleLabel?.textAlignment = .right
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.contentHorizontalAlignment = .right
    }
    
    private func setConstraints() {
        l.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        
        btn.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(6)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func showMorePressed(_ sender: UIButton) {
        self.delegate?.showMorePressed()
    }
    
}

