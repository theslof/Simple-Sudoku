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
    private var currentGame: Sudoku?
    
    //MARK: - Outlets
    
    @IBOutlet weak var outletNewGameButton: UIButton!
    @IBOutlet weak var outletContinueButton: UIButton!
    
    //MARK: - Default overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Uncomment the following row to clear the saved game data at launch
        //UserDefaults.standard.removeObject(forKey: defaultsKeys.CURRENT_GAME)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentGame: Sudoku = loadCurrentGame() {
            debugPrint("Successfully loaded game data!")
            canContinue = true
            self.currentGame = currentGame
        } else {
            debugPrint("Failed to load save game data!")
            canContinue = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "continueSegue":
            if let view = segue.destination as? GameBoardVC {
                view.sudoku = currentGame ?? Sudoku()
            }
        default:
            super.prepare(for: segue, sender: sender)
        }

    }
}
