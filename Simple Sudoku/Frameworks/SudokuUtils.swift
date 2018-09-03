//
//  SudokuUtils.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-03.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation

struct Globals {
    static let BLOCK_SIZE = 9
    static let BOARD_SIZE = BLOCK_SIZE * BLOCK_SIZE
    static let SUDOKU_SELL_REUSABLE_ID = "sudoku_cell"
}

struct Sudoku:Codable {
    var given: [Int]
    var solved: [Int]
    //var seed: Int
}

func blankSudoku() -> Sudoku {
    return Sudoku.init(given: Array(repeating: 0, count: Globals.BOARD_SIZE), solved: Array(repeating: 0, count: Globals.BOARD_SIZE))
}

func parseSudoku(from puzzle: String) -> Sudoku {
    if(puzzle.count > Globals.BOARD_SIZE) {
        fatalError("Error: Sudoku size too large")
    }

    var sudoku: [Int] = Array(repeating: 0, count: Globals.BOARD_SIZE)
    
    for (index, char) in puzzle.enumerated() {
        let num = Int(String(char)) ?? -1
        if (num < 0 || num > 9) {
            fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(char)")
        }

        sudoku[index] = num
    }

    return Sudoku.init(given: sudoku, solved: sudoku)
}
