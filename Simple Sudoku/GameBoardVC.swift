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

 - TODO: Add timer?
 */
class GameBoardVC: UIViewController {
    // MARK: - Variables
    var sudoku: Sudoku = Sudoku()
    var locked: [Bool] = Array(repeating: false, count: Globals.BOARD_SIZE)
    var selectedCell: IndexPath? = nil
    var isSolved = false

    // MARK: - Outlets
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var gameBoardCV: UICollectionView!
    @IBOutlet weak var buttonUndo: UIButtonRounded!

    override func viewDidLoad() {
        super.viewDidLoad()

        gameBoardCV.delegate = self
        gameBoardCV.dataSource = self
        buttonUndo.isEnabled = false

        loadSudoku()

        // Save the sudoku puzzle to memory
        addGame(seed: String(sudoku.seed))
        saveGame(sudoku: sudoku)
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
    */

    func loadSudoku() {
        // Make sure that our Sudoku has the correct size for our board
        if (sudoku.solved.count != Globals.BOARD_SIZE) {
            abortWith(message: "Error: Sudoku puzzle does not conform to board size")
        }

        // Make sure that each cell lies within accepted values...
        for (index, num) in sudoku.solved.enumerated() {
            if (num < 0 || num > Globals.ROW_SIZE) {
                abortWith(message: "Error: Sudoku cell value at position \(index) invalid! Was \(num)")
            }

            // ...and lock cells with given values
            locked[index] = sudoku.given[index] != 0
        }

        buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
        if (sudoku.isSolved()) {
            gameOver()
        }
    }

    private func abortWith(message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: ":(", style: .destructive) { _ in
            self.navigationController?.popToRootViewController(animated: true)
         })
        self.present(ac, animated: true)
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

        clearErrorLayers()

        if (value < 0 || value > 9) {
            abortWith(message: "Error: Sudoku cell value at position \(index) invalid! Was \(value)")
        }

        if sudokuUtils(addMove: Sudoku.HistoryItem(position: index, number: value), to: sudoku) {
            buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
            selectedCell = nil
            gameBoardCV.reloadData()
            saveGame(sudoku: sudoku)

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

    /// Undo the last move made
    func undoMove() {
        // Try to undo a move
        if sudokuUtils(undoMoveFrom: sudoku) {
            // We successfully undid a move, update UI and save the data
            buttonUndo.isEnabled = sudokuUtils(hasMovesInHistory: sudoku)
            gameBoardCV.reloadData()
            saveGame(sudoku: sudoku)
        }
    }

    /// Check the puzzle and highlight the next best move, or highlight any errors
    func getHint() {
        debugPrint("getHint():")
        var hasErrors = false

        // First we check for errors and highlight them as we find them
        let errors = sudoku.getErrors()
        hasErrors = !errors.isEmpty

        drawConflictFor(errors: errors)

        if hasErrors {
            return
        }

        let qq: QQWing = QQWing(sudoku.seed)
        let _ = qq.setPuzzle(sudoku.given)
        qq.setRecordHistory(true)
        let _ = qq.solve()

        // If there are no errors and we have a solution, highlight the best move
        if qq.isSolved() {
            debugPrint("Solution found!")
            // Solution found
            // Do something with qq.getSolveHistory().first
            for solution in qq.getSolveInstructions() {
                let legal = [LogType.SINGLE, LogType.HIDDEN_SINGLE_COLUMN, LogType.HIDDEN_SINGLE_ROW, LogType.HIDDEN_SINGLE_ROW, LogType.HIDDEN_SINGLE_SECTION, LogType.HIDDEN_SINGLE_SECTION, LogType.GUESS]
                if !locked[solution.position] && sudoku.solved[solution.position] == 0 && legal.contains(solution.type) {
                    selectCell(at: IndexPath(row: solution.position, section: 0))
                    break
                }
            }
        }
    }

    private func drawConflictFor(errors: [Sudoku.Error]) {
        clearErrorLayers()

        for error in errors {
            guard let first: SudokuCell = getCell(at: error.first), let second: SudokuCell = getCell(at: error.second)
                    else { continue }
            first.setError(true)
            second.setError(true)

            drawCircleOn(layer: errorView.layer, cell: first)
            drawCircleOn(layer: errorView.layer, cell: second)

            drawLineBetweenCirclesOn(layer: errorView.layer, cell1: first, cell2: second)

        }
    }

    private func clearErrorLayers() {
        errorView.layer.sublayers?.forEach { sublayer in
            sublayer.removeFromSuperlayer()
        }
    }

    private func drawCircleOn(layer: CALayer, cell: SudokuCell) {
        let sublayer = CAShapeLayer()
        let radius = cell.frame.width * 0.5
        let x = cell.frame.origin.x + radius
        let y = cell.frame.origin.y + radius


        let circlePath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: radius * 0.8, startAngle: CGFloat(0),
                endAngle:CGFloat(Double.pi * 2), clockwise: true)

        sublayer.path = circlePath.cgPath

        sublayer.fillColor = UIColor.clear.cgColor
        sublayer.strokeColor = UIColor.red.cgColor
        sublayer.lineWidth = 2.0

        layer.addSublayer(sublayer)
    }

    private func drawLineBetweenCirclesOn(layer: CALayer, cell1: SudokuCell, cell2: SudokuCell) {
        let sublayer = CAShapeLayer()
        var radius = CGFloat(cell1.frame.width * 0.5)
        let x1 = cell1.frame.origin.x + radius
        let y1 = cell1.frame.origin.y + radius
        let x2 = cell2.frame.origin.x + radius
        let y2 = cell2.frame.origin.y + radius
        radius *= 0.8

        let dx = x2 - x1
        let dy = y2 - y1
        // let distance = sqrtf(dx * dx + dy * dy) - Float(radius) * 2

        let angle = atan2(dx, dy)

        let ox1 = x1 + radius * sin(angle)
        let ox2 = x2 - radius * sin(angle)
        let oy1 = y1 + radius * cos(angle)
        let oy2 = y2 - radius * cos(angle)


        let path = UIBezierPath()
        path.move(to: CGPoint(x: ox1, y: oy1))
        path.addLine(to: CGPoint(x: ox2, y: oy2))

        sublayer.path = path.cgPath

        sublayer.fillColor = UIColor.clear.cgColor
        sublayer.strokeColor = UIColor.red.cgColor
        sublayer.lineWidth = 2.0

        layer.addSublayer(sublayer)
    }

    /// The sudoku is solved; lock down the board, remove the save data from memory and display a message to the user.
    func gameOver() {
        isSolved = true
        clearSavedGameFor(seed: String(sudoku.seed))
        let ac: UIAlertController = UIAlertController(title: "Solved!", message: "You found the solution!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        ac.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
            // The user pressed Exit, so we pop the last view controller and navigate away
            self.navigationController?.popToRootViewController(animated: true)
        }))
        self.present(ac, animated: true)
    }

    private func getCell(at cell: Int) -> SudokuCell? {
        return getCell(at: IndexPath(row: cell, section: 0))
    }

    private func getCell(at indexPath: IndexPath) -> SudokuCell? {
        return gameBoardCV.cellForItem(at: indexPath) as? SudokuCell
    }

    private func selectCell(at indexPath: IndexPath) {
        //Selected a cell. Deselect previously selected cell
        if let selectedCell = selectedCell, let oldCell = getCell(at: selectedCell) {
            oldCell.selectCell(false)
        }

        if isSolved { return }
        let cell = getCell(at: indexPath)
        cell?.selectCell(true)
        selectedCell = indexPath
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
        selectCell(at: indexPath)
    }
}
