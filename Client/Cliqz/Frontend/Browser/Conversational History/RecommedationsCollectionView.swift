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

protocol RecommendationsProtocol {
    func numberOfItems() -> Int
    func cellType(indexPath: IndexPath) -> RecommendationsCellType
    func text(indexPath: IndexPath) -> String
    func dateText(indexPath: IndexPath) -> String
    func picture(indexPath: IndexPath) -> UIImage?
    func time(indexPath: IndexPath) -> String
}

class RecommedationsCollectionView: UICollectionView {
    
    let cellReuseId = "recommedationsCell"
    let customLayout = RecommedationsCollectionLayout()
    var recomDataSource: RecommendationsProtocol? = nil
    
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
        cell.textLabel.text = recomDataSource?.text(indexPath: indexPath)
        cell.dateLabel.text = recomDataSource?.dateText(indexPath: indexPath)
        cell.pictureView.image = recomDataSource?.picture(indexPath: indexPath)
        cell.timeLabel.text = recomDataSource?.time(indexPath: indexPath)
        cell.cellType = recomDataSource?.cellType(indexPath: indexPath) ?? .Recommendation
        cell.updateState(indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recomDataSource?.numberOfItems() ?? 0
    }
    
}

extension RecommedationsCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 180, height: 188)
    }
}

extension RecommedationsCollectionView: RecommendationsCellDelegate {
    func deletePressed(indexPath: IndexPath) {
        debugPrint("delete pressed")
    }
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

