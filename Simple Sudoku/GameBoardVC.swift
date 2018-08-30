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
    
    ///MARK: - Outlets
    @IBOutlet weak var gameBoardCV: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        gameBoardCV.delegate = self
        gameBoardCV.dataSource = self
        
        for (index, char) in "000008000000406070000100503005000064000983000800000000060000097050000100001670030".enumerated() {
            sudoku[index] = Int8(String(char)) ?? 0
        }
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

}

extension GameBoardVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sudoku.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sudoku_cell", for: indexPath)
        let val = sudoku[indexPath.row]

        if val != 0 {
            (cell as? SudokuCell)?.cellLabel?.text = String(val)
            cell.layer.backgroundColor = UIColor(hue: 0.5, saturation: 1.0, brightness: 0.5, alpha: 1.0).cgColor
        } else {
            (cell as? SudokuCell)?.cellLabel?.text = ""
        }

        //cell.layer.borderWidth = CGFloat(GameBoardVC.CELL_BORDER_THIN)
        //cell.layer.borderColor = UIColor(white: 0.0, alpha: 1.0).cgColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.frame.width / 9 //- CGFloat(GameBoardVC.CELL_BORDER_THIN * 6 - GameBoardVC.CELL_BORDER_THICK * 2)

        return CGSize(width: w, height: w)
    }
}
