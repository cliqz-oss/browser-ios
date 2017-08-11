//
//  CustomPageControl.swift
//  DashboardComponent
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

final class CustomDots: UIView {
    
    private var dotsArray: [UIView] = []
    var currentPage: Int = 0
    var numberOfPages: Int = 0
    
    private let dotContainer = UIView()
    
    //styling
    
    private let dotSize: CGFloat = 8.0
    private let dotSpacing: CGFloat = 8.0
    private let selectedDotColor: UIColor = .white
    private let standardDotColor: UIColor = .lightGray
    
    init(numberOfPages: Int) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.numberOfPages = numberOfPages
        
        setUpComponents()
        setStyling()
        setConstraints()
    }
    
    func changePage(page:Int) {
        if pageWithinBounds(page: page) {
            
            UIView.animate(withDuration: 0.3, animations: {
                self.dotsArray[self.currentPage].backgroundColor = self.standardDotColor
                self.dotsArray[page].backgroundColor = self.selectedDotColor
                self.currentPage = page
            })
            
        }
    }
    
    private func setUpComponents() {
        
        dotsArray = generateDots()
        for dot in dotsArray {
            dotContainer.addSubview(dot)
        }
        
        self.addSubview(dotContainer)
    }
    
    private func setStyling() {
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dotContainer.backgroundColor = .clear
        
        if pageWithinBounds(page: currentPage) {
            dotsArray[currentPage].backgroundColor = selectedDotColor //assume initial position at 0
        }
        
    }
    
    private func setConstraints() {
        
        dotContainer.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(dotContainerWidth())
        }
        
        //handle the first dot
        
        if dotsArray.count > 0 {
            
            let firstDot = dotsArray[0]
            firstDot.snp.makeConstraints({ (make) in
                make.centerY.equalToSuperview()
                make.height.width.equalTo(dotSize)
                make.left.equalToSuperview()
            })
            
            var previousDot = firstDot
            
            for i in 1..<dotsArray.count {
                
                let dot = dotsArray[i]
                
                dot.snp.makeConstraints({ (make) in
                    make.centerY.equalToSuperview()
                    make.height.width.equalTo(dotSize)
                    make.left.equalTo(previousDot.snp.right).offset(dotSpacing)
                })
                
                previousDot = dot
            }
        }
        
    }
    
    private func generateDots() -> [UIView] {
        
        var array: [UIView] = []
        
        for _ in 0..<numberOfPages {
            array.append(createDot())
        }
        
        return array
        
    }
    
    private func createDot() -> UIView {
        let dot = UIView()
        dot.layer.cornerRadius = dotSize / 2.0
        dot.backgroundColor = standardDotColor
        return dot
    }
    
    private func dotContainerWidth() -> CGFloat {
        return CGFloat(numberOfPages) * dotSize + CGFloat(numberOfPages - 1) * dotSpacing
    }
    
    private func pageWithinBounds(page: Int) -> Bool {
        if page < numberOfPages && page >= 0 {
            return true
        }
        
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
