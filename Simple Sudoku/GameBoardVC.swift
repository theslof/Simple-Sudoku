//
//  GameBoardVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-30.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class GameBoardVC: UIViewController {

    /**

    TODO: Add custom class for buttons
    TODO: Write a solver
    TODO: Select/unselect cells
    TODO: Connect buttons to set/unset cells
    TODO: Lock preset cells and make labels bold
    TODO: Log history
    TODO: Save progress
    TODO: Resume saved games

    */
    
    ///MARK: - Variables
    static let BLOCK_SIZE = 9
    static let BOARD_SIZE = BLOCK_SIZE * BLOCK_SIZE
    static let CELL_MINIMUM_SPACE = 0
    static let CELL_BORDER_THIN = 1.0
    static let CELL_BORDER_THICK = 2.0
    var sudoku: [Int8] = Array(repeating: 0, count: BOARD_SIZE)
    var locked: [Bool] = Array(repeating: false, count: BOARD_SIZE)
    var selectedCell: IndexPath? = nil
    
    ///MARK: - Outlets
    @IBOutlet weak var gameBoardCV: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        gameBoardCV.delegate = self
        gameBoardCV.dataSource = self
        
        loadSudoku("000008000000406070000100503005000064000983000800000000060000097050000100001670030")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func loadSudoku(_ sud: String) {
        for (index, char) in sud.enumerated() {
            let num = Int8(String(char)) ?? 0
            sudoku[index] = num
            
            if(num != 0){
                locked[index] = true
            }
            
            //gameBoardCV.reloadData()
        }
    }

}

extension GameBoardVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sudoku.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sudoku_cell", for: indexPath) as! SudokuCell
        let val = sudoku[indexPath.row]
        
        cell.setNumber(to: val)
        cell.lockCell(locked[indexPath.row])
        
        //cell.layer.borderWidth = CGFloat(GameBoardVC.CELL_BORDER_THIN)
        //cell.layer.borderColor = UIColor(white: 0.0, alpha: 1.0).cgColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.frame.width / 9 //- CGFloat(GameBoardVC.CELL_BORDER_THIN * 6 - GameBoardVC.CELL_BORDER_THICK * 2)

        return CGSize(width: w, height: w)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Selected a cell, do some magic
        if selectedCell != nil {
            let oldCell = collectionView.cellForItem(at: selectedCell!) as! SudokuCell
            oldCell.selectCell(false)
        }
        let cell = collectionView.cellForItem(at: indexPath) as! SudokuCell
        cell.selectCell(true)
        selectedCell = indexPath
    }
}
