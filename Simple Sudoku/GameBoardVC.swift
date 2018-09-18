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
    - Track puzzle completion, inform user of success
    - Add timer?
    - Optimization of solver
 */
class GameBoardVC: UIViewController {
    // MARK: - Variables
    var sudoku: Sudoku = Sudoku()
    var locked: [Bool] = Array(repeating: false, count: Globals.BOARD_SIZE)
    var selectedCell: IndexPath? = nil
    var isSolved = false

    // MARK: - Outlets
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
        if (sudoku.isSolved()) {
            gameOver()
        }
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
                    gameOver()
                }
            }
        }
    }

    // Undo the last move made
    func undoMove() {
        // Try to undo a move
        if sudokuUtils(undoMoveFrom: sudoku) {
            // We successfully undid a move, update UI and save the data
            buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
            gameBoardCV.reloadData()
            saveCurrentGame(sudoku: sudoku)
        }
    }

    func getHint() {
        debugPrint("getHint():")
        let qq: QQWing = QQWing(sudoku.seed)
        let _ = qq.setPuzzle(sudoku.given)
        qq.setRecordHistory(true)
        let _ = qq.solve()
        var hasErrors = false

        for (i, correct) in qq.getSolution().enumerated() {
            if locked[i] || sudoku.solved[i] == 0 {
                continue
            }

            print("Solved: \(sudoku.solved[i]), correct: \(correct)")
            if sudoku.solved[i] != correct {
                hasErrors = true
                let errorCell = IndexPath(row: i, section: 0)

                if let cell = gameBoardCV.cellForItem(at: errorCell) as? SudokuCell {
                    cell.setError(true)
                }
            }
        }

        if (!hasErrors && qq.isSolved()) {
            debugPrint("Solution found!")
            // Solution found
            // Do something with qq.getSolveHistory().first
            for solution in qq.getSolveInstructions() {
                let legal = [LogType.SINGLE, LogType.HIDDEN_SINGLE_COLUMN, LogType.HIDDEN_SINGLE_ROW, LogType.HIDDEN_SINGLE_ROW, LogType.HIDDEN_SINGLE_SECTION, LogType.HIDDEN_SINGLE_SECTION, LogType.GUESS]
                if !locked[solution.position] && sudoku.solved[solution.position] == 0 && legal.contains(solution.type) {
                    if let old = selectedCell {
                        (gameBoardCV.cellForItem(at: old) as! SudokuCell).selectCell(false)
                    }

                    debugPrint("Selecting cell at \(solution.position)")
                    selectedCell = IndexPath(row: solution.position, section: 0)

                    if let selectedCell = selectedCell, let cell = gameBoardCV.cellForItem(at: selectedCell) as? SudokuCell {
                        print("Found cell")
                        cell.selectCell(true)
                    }

                    break
                }
            }
        }
    }

    func gameOver() {
        isSolved = true
        clearSavedGame()
        let ac: UIAlertController = UIAlertController(title: "Solved!", message: "You found the solution!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        ac.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(ac, animated: true)
    }

    //MARK: - Actions

    @IBAction func buttonTapped(_ sender: UIButton) {
        if isSolved { return }

        switch sender.tag {
        case 0...9:
            // Pressed a number
            setSelectedCell(to: sender.tag)
        case 10:
            // Pressed Hint
                getHint()
        case 11:
            // Pressed Undo button
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
        //Selected a cell. Deselect previously selected cell
        if selectedCell != nil {
            let oldCell = collectionView.cellForItem(at: selectedCell!) as! SudokuCell
            oldCell.selectCell(false)
        }

        if isSolved { return }
        let cell = collectionView.cellForItem(at: indexPath) as! SudokuCell
        cell.selectCell(true)
        selectedCell = indexPath
    }
}
