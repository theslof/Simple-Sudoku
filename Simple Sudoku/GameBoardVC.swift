//
//  GameBoardVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-30.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

/**
 View Controller for the game board view.

 - TODO:
    - Write a solver
    - Log history
    - Optimization of solver
 */
class GameBoardVC: UIViewController {
    //MARK: - Variables
    var sudoku: Sudoku = Sudoku()
    var locked: [Bool] = Array(repeating: false, count: Globals.BOARD_SIZE)
    var selectedCell: IndexPath? = nil

    //MARK: - Outlets
    @IBOutlet weak var gameBoardCV: UICollectionView!
    @IBOutlet weak var buttonUndo: UIButtonRounded!

    override func viewDidLoad() {
        super.viewDidLoad()

        gameBoardCV.delegate = self
        gameBoardCV.dataSource = self
        buttonUndo.isEnabled = false

        loadSudoku()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

    //MARK: - Functions

    /**
    Parse a string of numbers and load the corresponding sudoku puzzle. If the puzzle string is too long, or contains any number outside 0-9, the functions throws a fatalError()

    - Author: Jonas Theslöf

    - parameter sud: The sudoku puzzle as a string of numbers

    - TODO: Better error handling
    */

    func loadSudoku() {
        // Make sure that our Sudoku has the correct size for our board
        if (sudoku.solved.count != Globals.BOARD_SIZE) {
            fatalError("Error: Sudoku puzzle does not conform to board size")
        }

        // Make sure that each cell lies within accepted values...
        for (index, num) in sudoku.solved.enumerated() {
            if (num < 0 || num > Globals.ROW_SIZE) {
                fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(num)")
            }

            // ...and lock cells with given values
            locked[index] = sudoku.given[index] != 0
        }

        buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
    }

    /**
    Set the value of the selected cell.

    - parameter to: The new value of the cell
    */
    func setSelectedCell(to value: Int) {
        // Only run function if the player have selected a cell
        guard let index = selectedCell?.row else {
            return
        }

        if (value < 0 || value > 9) {
            fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(value)")
        }

        if sudokuUtils(addMove: Sudoku.HistoryItem(position: index, number: value), to: sudoku) {
            buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
            selectedCell = nil
            gameBoardCV.reloadData()
            saveCurrentGame(sudoku: sudoku)

            if(!sudoku.isLegal()) {
                // Sudoku does not conform to rules, ie. the player made an illegal move.
            } else {
                if(sudoku.isSolved()) {
                    // Sudoku is solved, inform the player
                }
            }
        }
    }

    func undoMove() {
        if sudokuUtils(undoMoveFrom: sudoku) {
            buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
            gameBoardCV.reloadData()
            saveCurrentGame(sudoku: sudoku)
        }
    }

    //MARK: - Actions

    @IBAction func buttonTapped(_ sender: UIButton) {

        switch sender.tag {
        case 0...9:
            //Pressed a number
            setSelectedCell(to: sender.tag)
        case 11:
            //Pressed Undo button
            undoMove()
        default:
            //Unknown button pressed
            debugPrint("Unknown tag")
            break
        }
    }
}

//MARK: - Extensions

extension GameBoardVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Globals.BOARD_SIZE
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Globals.SUDOKU_SELL_REUSABLE_ID, for: indexPath) as! SudokuCell
        let val = sudoku.solved[indexPath.row]

        cell.setNumber(to: val)
        cell.lockCell(locked[indexPath.row])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.frame.width / 9

        return CGSize(width: w, height: w)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Selected a cell. Deselect previously selected cell and
        if selectedCell != nil {
            let oldCell = collectionView.cellForItem(at: selectedCell!) as! SudokuCell
            oldCell.selectCell(false)
        }
        let cell = collectionView.cellForItem(at: indexPath) as! SudokuCell
        cell.selectCell(true)
        selectedCell = indexPath
    }
}
