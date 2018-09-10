//
//  SudokuCellCollectionViewCell.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-30.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class SudokuCell: UICollectionViewCell {
    
    //MARK: - Outlets
    @IBOutlet weak var cellLabel: UILabel!
    
    //MARK: - Members
    
    static let defaultColor: CGColor = UIColor.white.cgColor
    static let lockedColor: CGColor = UIColor.paleGray.cgColor
    static let selectedColor: CGColor = UIColor.paleBlue.cgColor

    // Is the cell locked (ie. has a starting value and should not be changed by the player)
    private var locked: Bool = false {
        didSet {
            if (locked) {
                cellLabel.font = UIFont.boldSystemFont(ofSize: cellLabel.font.pointSize)
            } else {
                cellLabel.font = UIFont.systemFont(ofSize: cellLabel.font.pointSize)
            }
            updateColor()
        }
    }
    
    // Is the cell selected (ie. highlighted by the player)
    private var cell_selected: Bool = false
        
    
    //MARK: - Functions
    
    private func updateColor() {
        if (locked) {
            self.layer.backgroundColor = SudokuCell.lockedColor
        } else if (cell_selected) {
            self.layer.backgroundColor = SudokuCell.selectedColor
        } else {
            self.layer.backgroundColor = SudokuCell.defaultColor
        }
    }
    
    func lockCell(_ state: Bool) {
        //If the cell is set as selected and we're about to lock it we need to unselect it first
        if (cell_selected && state) {
            cell_selected = false
        }
        
        locked = state
    }
    
    func selectCell(_ state: Bool) {
        if (!locked) {
            cell_selected = state
            updateColor()
        }
    }
    
    func setNumber(to num: Int) {
        self.cellLabel.text = num != 0 ? String(num) : ""
    }
    
    override func prepareForReuse() {
        locked = false
        cell_selected = false
        self.cellLabel.text = ""
        updateColor()
    }
}
