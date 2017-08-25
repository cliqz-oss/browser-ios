//
//  DomainDetailsViewController
//  Client
//
//  Created by Tim Palade.

import Foundation
import UIKit
import SnapKit
import Alamofire
import QuartzCore

// This is the View Controller for the Domain Details View (What you see after you press on a certain domain)

final class DomainDetailsViewController: UIViewController {
	
	var historyTableView: BubbleTableView!
    var headerView: DomainDetailsHeaderView!
    let recommendationsCollection = RecommedationsCollectionView()
    
    var tableViewDataSource: BubbleTableViewDataSource
    var recommendationsDataSource: RecommendationsCollectionProtocol
    var headerViewDataSource: DomainDetailsHeaderViewProtocol
	
    var didPressBack: () -> ()
    var cellPressed: (String) -> Void
    
    init(tableViewDataSource: BubbleTableViewDataSource, recommendationsDataSource: RecommendationsCollectionProtocol, headerViewDataSource: DomainDetailsHeaderViewProtocol, didPressBack: @escaping () -> (), cellPressed: @escaping (String) -> Void) {
        
        self.tableViewDataSource = tableViewDataSource
        self.recommendationsDataSource = recommendationsDataSource
        self.headerViewDataSource = headerViewDataSource
        
        self.didPressBack = didPressBack
        self.cellPressed = cellPressed
        
        super.init(nibName: nil, bundle: nil)
        
        historyTableView = BubbleTableView(customDataSource: self.tableViewDataSource, customDelegate: self)
        recommendationsCollection.customDataSource = self.recommendationsDataSource
        headerView = DomainDetailsHeaderView(dataSource: self.headerViewDataSource)
        headerView.delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()
        
        componentSetUp()
        setStyling()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        if recommendationsDataSource.numberOfItems() == 0 {
            recommendationsCollection.isHidden = true
        }
        else {
            recommendationsCollection.isHidden = false
        }
        
        setConstraints()
    }
    
    private func componentSetUp() {
        self.view.addSubview(headerView)
        self.view.addSubview(recommendationsCollection)
        self.view.addSubview(historyTableView)
    }
    
    private func setStyling() {
        self.view.backgroundColor = UIColor.clear
    }
    
    private func setConstraints() {
        
        self.headerView.snp.remakeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }
        
        self.recommendationsCollection.snp.makeConstraints { (make) in
            
            let height = recommendationsDataSource.numberOfItems() == 0 ? 0 : 204
            
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.height.equalTo(height)
        }
        
        self.historyTableView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.recommendationsCollection.snp.bottom)
        }
    }
	
	@objc private func logoPressed() {

	}
}

extension DomainDetailsViewController: BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath) {
        self.cellPressed(tableViewDataSource.url(indexPath: indexPath))
    }
}

extension DomainDetailsViewController: DomainDetailsHeaderViewDelegate {
    func headerLogoPressed() {
        
    }
    
    func headerGoBackPressed() {
        didPressBack()
    }
}

