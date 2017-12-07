//
//  MigrationViewController.swift
//  Client
//
//  Created by Tim Palade on 12/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class MigrationViewController: UIViewController {
    
    let titleLabel = UILabel()
    let progressBar = UIProgressView()
    let spinner = UIActivityIndicatorView()
    let explanation = UILabel()
    let containerExplanation = UIView()
    let container = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUp()
        setStyling()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.startAnimating()
    }
    
    private func setUp() {
        
        containerExplanation.addSubview(titleLabel)
        containerExplanation.addSubview(explanation)
        container.addSubview(containerExplanation)
        container.addSubview(progressBar)
        container.addSubview(spinner)
        self.view.addSubview(container)
        
        titleLabel.text = "Migrating History"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: 600)
        progressBar.setProgress(0.0, animated: false)
        
        explanation.numberOfLines = 0
        explanation.text = "This should take a less than a minute. Please wait and DON'T close the app. Thank you for the understanding! Tim. \n\nP.S I played with the DataBase."
    }
    
    private func setStyling() {
        self.view.backgroundColor = .white
        
        spinner.activityIndicatorViewStyle = .white
        spinner.color = .black
        
    }
    
    private func setConstraints() {
        
        container.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.2)
            make.height.equalToSuperview().dividedBy(1.5)
        }
        
        containerExplanation.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(1.5)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        explanation.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        progressBar.snp.makeConstraints { (make) in
            make.top.equalTo(self.containerExplanation.snp.bottom)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        spinner.snp.makeConstraints { (make) in
            make.top.equalTo(self.progressBar.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
