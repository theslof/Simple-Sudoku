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
    static let lockedColor: CGColor = UIColor.sudokuLocked.cgColor
    static let selectedColor: CGColor = UIColor.sudokuHighlight.cgColor
    static let defaultTextColor: UIColor = UIColor.black
    static let errorTextColor: UIColor = UIColor.sudokuError

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
    private var cellHasError: Bool = false
        
    
    //MARK: - Functions

    private func updateColor() {
        updateColor(animated: false)
    }

    private func updateColor(animated: Bool) {
        var newBgColor = SudokuCell.defaultColor
        var newTextColor = SudokuCell.defaultTextColor
        if (locked) {
            newBgColor = SudokuCell.lockedColor
        } else if (cell_selected) {
            newBgColor = SudokuCell.selectedColor
        } else {
            newBgColor = SudokuCell.defaultColor
        }

        if (cellHasError) {
            newTextColor = SudokuCell.errorTextColor
        } else {
            newTextColor = SudokuCell.defaultTextColor
        }

        if animated {
            UIView.animate(withDuration: 0.20) {
                self.layer.backgroundColor = newBgColor
                self.cellLabel.textColor = newTextColor
            }
        } else {
            self.layer.backgroundColor = newBgColor
            self.cellLabel.textColor = newTextColor
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
            updateColor(animated: true)
        }
    }

    func setError(_ state: Bool) {
        if (!locked) {
            cellHasError = state
            updateColor(animated: true)
        }
    }

    func setNumber(to num: Int) {
        self.cellLabel.text = num != 0 ? String(num) : ""
    }
    
    override func prepareForReuse() {
        locked = false
        cell_selected = false
        cellHasError = false
        self.cellLabel.text = ""
        updateColor()
    }
}
