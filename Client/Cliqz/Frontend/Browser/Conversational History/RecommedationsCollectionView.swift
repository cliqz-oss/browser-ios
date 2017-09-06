//
//  RecommedationsCollectionView.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum RecommendationsCellType {
    case Recommendation
    case Reminder
}

protocol RecommendationsCollectionProtocol {
    func numberOfItems() -> Int
    func cellType(indexPath: IndexPath) -> RecommendationsCellType
    func text(indexPath: IndexPath) -> String
    func headerTitle(indexPath: IndexPath) -> String
    func picture(indexPath: IndexPath, completion: @escaping (UIImage?) -> Void)
    func time(indexPath: IndexPath) -> String
    func url(indexPath: IndexPath) -> String 
}

protocol RecommendationsCollectionDelegate: class {
    func itemPressed(indexPath: IndexPath)
    func deletePressed(indexPath: IndexPath)
}

class RecommedationsCollectionLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.minimumInteritemSpacing = 20.0
        self.minimumLineSpacing = 10.0
        self.scrollDirection = .horizontal
        self.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class RecommedationsCollectionView: UICollectionView {
    
    let cellReuseId = "recommedationsCell"
    let customLayout = RecommedationsCollectionLayout()
    var customDataSource: RecommendationsCollectionProtocol? = nil
    
    let minHeight: CGFloat = 0.0
    let maxHeight: CGFloat = 204.0
    var currentHeight: CGFloat = 204.0 //Initial
    var prevHeight: CGFloat = 204.0
    
    weak var customDelegate: RecommendationsCollectionDelegate? = nil
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: customLayout)
        componentSetUp()
        setStyling()
    }
    
    func componentSetUp() {
        self.dataSource = self
        self.delegate = self
        self.register(RecommendationsCell.self, forCellWithReuseIdentifier: cellReuseId)
    }
    
    func setStyling() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RecommedationsCollectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! RecommendationsCell
        cell.tag = indexPath.item
        cell.textLabel.text = customDataSource?.text(indexPath: indexPath)
        cell.headerLabel.text = customDataSource?.headerTitle(indexPath: indexPath)
        customDataSource?.picture(indexPath: indexPath, completion: { (image) in
            if cell.tag == indexPath.item {
                cell.pictureView.image = image
            }
        })
        cell.timeLabel.text = customDataSource?.time(indexPath: indexPath)
        cell.cellType = customDataSource?.cellType(indexPath: indexPath) ?? .Recommendation
        cell.updateState(indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return customDataSource?.numberOfItems() ?? 0
    }
    
}

extension RecommedationsCollectionView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 180, height: 188)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        customDelegate?.itemPressed(indexPath: indexPath)
    }
}

extension RecommedationsCollectionView: RecommendationsCellDelegate {
    func deletePressed(indexPath: IndexPath) {
        debugPrint("delete pressed")
        customDelegate?.deletePressed(indexPath: indexPath)
    }
}

extension RecommedationsCollectionView {
    func height() -> CGFloat {
        return (customDataSource?.numberOfItems() ?? 0) > 0 ? maxHeight : minHeight
    }
}


//scroll animation
extension RecommedationsCollectionView {
    
    func canPerformChanges() -> Bool {
        return customDataSource?.numberOfItems() ?? 0 > 0
    }
    
    func adjustConstraints(offset: CGFloat) {
        
        guard canPerformChanges() else {
            return
        }
        
        let proposed_height = currentHeight - offset
        let newHeight = min(max(minHeight, proposed_height), maxHeight)
        
        self.snp.updateConstraints { (make) in
            make.height.equalTo(newHeight)
        }
        
        setCurrentHeight(height: newHeight)
        
        self.layoutIfNeeded()
    }
    
    func adjustOpacity() {
        
        guard canPerformChanges() else {
            return
        }
        
        self.alpha = currentHeight / maxHeight
    }
    
    func expand() {
        
        guard canPerformChanges() else {
            return
        }
        
        setExpanded()
        setVisible()
    }
    
    func collapse() {
        
        guard canPerformChanges() else {
            return
        }
        
        setCollapsed()
        setInvisible()
    }
    
    func percentageExpanded() -> CGFloat {
        return currentHeight / maxHeight
    }
    
    func finishTransition() {
        
        guard canPerformChanges() else {
            return
        }
        
        if currentHeight > prevHeight {
            setExpanded()
            setVisible()
        }
        else if currentHeight < prevHeight {
            setCollapsed()
            setInvisible()
        }
    }
    
    private func setCurrentHeight(height: CGFloat) {
        guard currentHeight != height else {
            return
        }
        
        prevHeight = currentHeight
        currentHeight = height
    }
    
    private func setExpanded() {
        
        setCurrentHeight(height: maxHeight)
        
        self.snp.updateConstraints { (make) in
            make.height.equalTo(maxHeight)
        }
        
        //self.layoutIfNeeded()
    }
    
    private func setCollapsed() {
        
        setCurrentHeight(height: minHeight)
        
        self.snp.updateConstraints { (make) in
            make.height.equalTo(minHeight)
        }
        
        //self.layoutIfNeeded()
    }
    
    private func setVisible() {
        self.alpha = 1.0
    }
    
    private func setInvisible() {
        self.alpha = 0.0
    }
    
    func timeFor(velocity: CGFloat) -> Double {
        if velocity == 0.0 {
            fatalError("division by 0 is undefined")
        }
        //compute the time v = delta x / t -> t = delta x / v , where t is in seconds.
        let delta_x = Double(maxHeight - minHeight)
        return (delta_x / Double(abs(velocity)))
    }
}


