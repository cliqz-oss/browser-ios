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
    
    //scroll
    var finger_on_screen: Bool = true
    var prev_offset: CGFloat = 0.0
    var animating: Bool = false
    
    enum ScrollDirection {
        case up
        case down
        case undefined
    }
    
    init(tableViewDataSource: BubbleTableViewDataSource, recommendationsDataSource: RecommendationsCollectionProtocol, headerViewDataSource: DomainDetailsHeaderViewProtocol, didPressBack: @escaping () -> (), cellPressed: @escaping (String) -> Void) {
        
        self.tableViewDataSource = tableViewDataSource
        self.recommendationsDataSource = recommendationsDataSource
        self.headerViewDataSource = headerViewDataSource
        
        self.didPressBack = didPressBack
        self.cellPressed = cellPressed
        
        super.init(nibName: nil, bundle: nil)
        
        historyTableView = BubbleTableView(customDataSource: self.tableViewDataSource, customDelegate: self)
        historyTableView.scrollViewDelegate = self
        recommendationsCollection.customDataSource = self.recommendationsDataSource
        headerView = DomainDetailsHeaderView(dataSource: self.headerViewDataSource)
        headerView.delegate = self
        
        let panGestureRec = historyTableView.panGestureRecognizer
        panGestureRec.addTarget(self, action: #selector(panHappened))
        
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
        
        setConstraints()
        
        animating = false
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
        
        self.headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }
        
        self.recommendationsCollection.snp.remakeConstraints { (make) in
            
            let height = recommendationsCollection.height()
            
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.height.equalTo(height)
        }
        
        self.historyTableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.recommendationsCollection.snp.bottom)//.offset(10)
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

extension DomainDetailsViewController: CustomScrollDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        finger_on_screen = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        finger_on_screen = false
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        finger_on_screen = false
    }
}


//Recommendations collapse on scroll of tableview
extension DomainDetailsViewController {
    @objc
    func panHappened(_ pan: UIPanGestureRecognizer) {
        
        let translation = pan.translation(in: historyTableView)
        let velocity = pan.velocity(in: historyTableView)
        let offset = -(translation.y - prev_offset)
        
        var direction: ScrollDirection = .undefined
        if velocity.y < 0.0 {
            direction = .up
        }
        else if velocity.y > 0.0 {
            direction = .down
        }
        
        if direction == .up {
            if recommendationsCollection.currentHeight != recommendationsCollection.minHeight && recommendationsCollection.canPerformChanges() {
                self.historyTableView.setContentOffset(CGPoint(x: 0, y:0), animated: false)
            }
            
            self.recommendationsCollection.adjustOpacity()
            self.recommendationsCollection.adjustConstraints(offset: offset)
        }
        else if direction == .down {
            if historyTableView.contentOffset.y < 0.5 {
                self.recommendationsCollection.adjustOpacity()
                self.recommendationsCollection.adjustConstraints(offset: offset)
            }
        }
        
        let time = abs(velocity.y) >= 340 ? recommendationsCollection.timeFor(velocity: velocity.y) : 0.6
        
        if finger_on_screen {
            prev_offset = translation.y
        }
        else {
            prev_offset = 0.0
            UIView.animate(withDuration: time, animations: {
                self.recommendationsCollection.finishTransition()
                self.view.layoutIfNeeded()
            })
        }
    }
}
