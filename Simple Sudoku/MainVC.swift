//
//  MainVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-23.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

/**
 Main menu View Controller
 
 - parameters:
    - canContinue: Is true if there are ongoing games that can be resumed.
 */
class MainVC: UIViewController {

    //MARK: - Parameters
    
    ///Tracks if the user can continue an existing game
    private var canContinue: Bool = false {
        didSet {
            self.outletContinueButton.isEnabled = canContinue
        }
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var outletContinueButton: UIButton!
    
    //MARK: - Default overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Actions
    
    @IBAction func actionContinueButtonTapped(_ sender: UIButton) {
        //TODO: Continue
    }
    
    @IBAction func actionNewGameButtonTapped(_ sender: UIButton) {
        //TODO: New Game
    }
    
    @IBAction func actionSettingsButtonTapped(_ sender: UIButton) {
        //TODO: Settings
    }
    
    @IBAction func actionAboutButtonTapped(_ sender: UIButton) {
        //TODO: About
    }
}
