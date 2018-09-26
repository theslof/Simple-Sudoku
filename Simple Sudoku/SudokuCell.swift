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
        var newBgColor = Sudoku.colorBackground
        var newTextColor = Sudoku.colorForeground
        if (locked) {
            newBgColor = Sudoku.colorLocked
        } else if (cell_selected) {
            newBgColor = Sudoku.colorHighlight
        }

        if (cellHasError) {
            newTextColor = Sudoku.colorError
        }

        if animated {
            UIView.animate(withDuration: 0.20) {
                self.layer.backgroundColor = newBgColor.cgColor
                self.cellLabel.textColor = newTextColor
            }
        } else {
            self.layer.backgroundColor = newBgColor.cgColor
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
