//
//  NewGameVCViewController.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-11.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

/**
 View Controller for setting up a new game.
 */
class NewGameVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var outletDifficulty: UIButton!
    @IBOutlet weak var outletSymmetry: UIButton!
    @IBOutlet weak var outletSeed: UIButton!
    @IBOutlet weak var outletIndicator: UIActivityIndicatorView!
    
    var difficulty: Difficulty = Difficulty.EASY
    var symmetry: Symmetry = Symmetry.RANDOM
    var seed: UInt64? {
        didSet {
            if let seed = seed {
                outletSeed.setTitle(String(seed), for: .normal)
                outletDifficulty.isEnabled = false
                outletSymmetry.isEnabled = false
            } else {
                outletSeed.setTitle("Random", for: .normal)
                outletDifficulty.isEnabled = true
                outletSymmetry.isEnabled = true
            }
        }
    }
    var sudoku: Sudoku?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Generate a new puzzle using a seed and the QQWing generator
    func generatePuzzle(from seed: UInt64) -> Sudoku{
        let qq = QQWing(seed)
        let _ = qq.generatePuzzleSymmetry(Symmetry.RANDOM)
        return Sudoku(qqwing: qq)
    }

    /// Generate a new puzzle from a selected difficulty and symmetry
    func generatePuzzle(difficulty: Difficulty, symmetry: Symmetry) -> Sudoku {
        var qq = QQWing()
        qq.setRecordHistory(true)
        repeat {
            qq = QQWing(randomSeed)
            qq.setRecordHistory(true)
            // Set a new seed and attempt to create a puzzle that match both symmetry and difficulty.
            // If the result has another difficulty or symmetry we need to generate a new seed and try again,
            // so that we can always get the same puzzle by simply supplying the same seed.
            let _ = qq.generatePuzzleSymmetry(Symmetry.RANDOM)
            let _ = qq.solve()
        } while (qq.getDifficulty() != difficulty && qq.symmetry != symmetry)
        return Sudoku(qqwing: qq)
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "startGameSegue":
            if let view = segue.destination as? GameBoardVC {
                // We have no saved game, we want to generate a new puzzle
                view.sudoku = self.sudoku ?? Sudoku()
            }
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    // MARK: - Actions
    @IBAction func startGameTapped(_ sender: UIButton) {
        // We have no saved game, we want to generate a new puzzle
        outletIndicator.startAnimating()
        DispatchQueue.global(qos: .default).async {
            if let seed = self.seed {
                self.sudoku = self.generatePuzzle(from: seed)
            } else {
                self.sudoku = self.generatePuzzle(difficulty: self.difficulty, symmetry: self.symmetry)
            }
            debugPrint("Generated a sudoku with seed: \(self.sudoku!.seed)")
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "startGameSegue", sender: self)
                self.outletIndicator.stopAnimating()
            }
        }
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            // Difficulty
            let ac: UIAlertController = UIAlertController(title: "Difficulty", message: "Select a difficulty:", preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Easy", style: .default, handler: {_ in
                self.difficulty = .EASY
                self.outletDifficulty.setTitle("Easy", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Medium", style: .default, handler: { _ in
                self.difficulty = .INTERMEDIATE
                self.outletDifficulty.setTitle("Medium", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Hard", style: .default, handler: { _ in
                self.difficulty = .EXPERT
                self.outletDifficulty.setTitle("Hard", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(ac, animated: true)
        case 2:
            // Symmetry
            let ac: UIAlertController = UIAlertController(title: "Symmetry", message: "Select a symmetry:", preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Random", style: .default, handler: {_ in
                self.symmetry = .RANDOM
                self.outletSymmetry.setTitle("Random", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Mirror", style: .default, handler: {_ in
                self.symmetry = .MIRROR
                self.outletSymmetry.setTitle("Mirror", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Flip", style: .default, handler: {_ in
                self.symmetry = .FLIP
                self.outletSymmetry.setTitle("Flip", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Rotate 90", style: .default, handler: {_ in
                self.symmetry = .ROTATE90
                self.outletSymmetry.setTitle("Rotate 90", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Rotate 180", style: .default, handler: {_ in
                self.symmetry = .ROTATE180
                self.outletSymmetry.setTitle("Rotate 180", for: .normal)
            }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(ac, animated: true)
        case 3:
            // Seed
            let ac: UIAlertController = UIAlertController(title: "Seed", message: "Enter a seed as a positive number:", preferredStyle: .alert)
            ac.addTextField {textField in
                if let seed = self.seed {
                    textField.text = String(seed)
                } else {
                    textField.placeholder = "Seed"
                }
            }
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            ac.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { _ in self.seed = nil }))
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let textField = ac.textFields?.first, textField.text != nil {
                    self.seed = UInt64(textField.text!)
                } else {
                    self.seed = nil
                }
            }))
            self.present(ac, animated: true)
        default:
            break
        }
    }
    
    
}
