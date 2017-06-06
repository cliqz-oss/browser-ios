//
//  LandscapeFlowLayout.swift
//  TabsRedesign
//
//  Created by Tim Palade on 3/29/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

class LandscapeFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.sectionInset = self.computeOptimalPadding()
        self.minimumInteritemSpacing = 2.0
        self.minimumLineSpacing = 20.0
		self.scrollDirection = .vertical
		
    }
    
    func minItemPadding() -> CGFloat {
        //the algorithm for computing the optimal padding will always return a padding greater than the minItemPadding
        return UIDevice.current.userInterfaceIdiom == .phone ? CGFloat(10) : CGFloat(20)
    }
    
    func computeOptimalPadding() -> UIEdgeInsets {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let cellSize = Knobs.landscapeSize()
        
        
        let items_per_row = floor((screenWidth - minItemPadding()) / (cellSize.width + minItemPadding()))
        let spaces_between_items = items_per_row + 1
        let availableSpace = screenWidth - (cellSize.width * items_per_row)
        let padding = floor(availableSpace / spaces_between_items)
        
        return UIEdgeInsetsMake(20.0, padding, 20.0, padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
