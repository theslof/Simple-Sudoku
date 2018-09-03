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
    - Save progress
    - Resume saved games
    - Write a generator
    - Optimization of solver
 */
class GameBoardVC: UIViewController {
    //MARK: - Variables
    static let BLOCK_SIZE = 9
    static let BOARD_SIZE = BLOCK_SIZE * BLOCK_SIZE
    static let CELL_MINIMUM_SPACE = 0
    static let CELL_BORDER_THIN = 1.0
    static let CELL_BORDER_THICK = 2.0
    var sudoku: [Int8] = Array(repeating: 0, count: BOARD_SIZE)
    var locked: [Bool] = Array(repeating: false, count: BOARD_SIZE)
    var selectedCell: IndexPath? = nil
    
    //MARK: - Outlets
    @IBOutlet weak var gameBoardCV: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameBoardCV.delegate = self
        gameBoardCV.dataSource = self
        
        loadSudoku("000008000000406070000100503005000064000983000800000000060000097050000100001670030")
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
    func loadSudoku(_ sud: String) {
        if(sud.count > GameBoardVC.BOARD_SIZE) {
            fatalError("Error: Sudoku size too large")
        }
        for (index, char) in sud.enumerated() {
            let num = Int8(String(char)) ?? -1
            if(num < 0 || num > 9) {
                fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(char)")
            }
            sudoku[index] = num
            
            if(num != 0){
                locked[index] = true
            }
            
            //gameBoardCV.reloadData()
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
        
        if(value < 0 || value > 9) {
            fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(value)")
        }
        sudoku[index] = Int8(value)
        selectedCell = nil
        gameBoardCV.reloadData()
    }
    
    //MARK: - Actions
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        
        switch sender.tag {
        case 0...9:
            //Pressed a number
            setSelectedCell(to: sender.tag)
        default:
            //Unknown button pressed
            print("Unknown tag")
            break
        }
    }
}

//MARK: - Extensions

extension GameBoardVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sudoku.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sudoku_cell", for: indexPath) as! SudokuCell
        let val = sudoku[indexPath.row]
        
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
