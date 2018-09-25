//
//  AboutVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-25.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class AboutVC: UIViewController {    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tappedGithubBtn(_ sender: UIButton) {
        if let url = URL(string: "https://github.com/theslof/Simple-Sudoku/") {
            UIApplication.shared.open(url, options: [:])
        }
    }
}
