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
        //clearAllSavedGames()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let games: [String] = loadGames()

        if let seed = games.first, let currentGame: Sudoku = loadGameFor(seed: seed) {
            // If we successfully loaded a game from memory...
            debugPrint("Successfully loaded game data!")
            canContinue = true
            self.currentGame = currentGame
        } else {
            //...or if we failed to do so:
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
        default:
            super.prepare(for: segue, sender: sender)
        }

    }
}
