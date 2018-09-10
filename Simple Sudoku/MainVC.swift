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
            if(canContinue) {
                self.outletNewGameButton.setTitle("Continue", for: .normal)
            } else {
                self.outletNewGameButton.setTitle("New Game", for: .normal)
            }
        }
    }

    ///Holds the data for the currently active game
    private var currentGame: Sudoku?
    
    //MARK: - Outlets
    
    @IBOutlet weak var outletNewGameButton: UIButton!
    
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
        case "newGameSegue":
            if currentGame == nil {
                currentGame = Sudoku(from: "300060207020009010109005800097806000800000006000503970002600501010900040408050009")
                let _ = currentGame?.solve(withRandomSeed: 1337)
                print("Generated sudoku: \(currentGame!)")
            }
            if let view = segue.destination as? GameBoardVC {
                view.sudoku = currentGame ?? Sudoku()
            }
        default:
            super.prepare(for: segue, sender: sender)
        }

    }
}
