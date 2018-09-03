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

    ///Holds the data for the currently active game
    private var currentGame: Sudoku = blankSudoku()
    
    //MARK: - Outlets
    
    @IBOutlet weak var outletContinueButton: UIButton!
    
    //MARK: - Default overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentGame: Sudoku = loadCurrentGame() {
            canContinue = true
            self.currentGame = currentGame
        } else {
            canContinue = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Actions
    
    @IBAction func actionContinueButtonTapped(_ sender: UIButton) {
        //TODO: Continue
        if let gameBoardVC = storyboard?.instantiateViewController(withIdentifier: "GameBoardVC") as? GameBoardVC {
            gameBoardVC.sudoku = currentGame
            navigationController?.pushViewController(gameBoardVC, animated: true)
        }
    }
    
    @IBAction func actionNewGameButtonTapped(_ sender: UIButton) {
        //TODO: New Game
        if let gameBoardVC = storyboard?.instantiateViewController(withIdentifier: "GameBoardVC") as? GameBoardVC {
            gameBoardVC.sudoku = parseSudoku(from: "000008000000406070000100503005000064000983000800000000060000097050000100001670030")
            navigationController?.pushViewController(gameBoardVC, animated: true)
        }
    }
    
    @IBAction func actionSettingsButtonTapped(_ sender: UIButton) {
        //TODO: Settings
    }
    
    @IBAction func actionAboutButtonTapped(_ sender: UIButton) {
        //TODO: About
    }
}
