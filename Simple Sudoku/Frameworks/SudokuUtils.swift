//
//  SudokuUtils.s?wift
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
    static let DEBUG_PRINT_ENABLED = true
}

class Sudoku: Codable {
    var given: [Int8]
    var solved: [Int8]
    var history: [HistoryItem]
    //var seed: Int

    struct HistoryItem: Codable {
        var position: Int
        var number: Int8
    }

    private enum CodingKeys: String, CodingKey {
        case given
        case solved
        case history
    }

    init() {
        self.given = Array(repeating: 0, count: Globals.BOARD_SIZE)
        self.solved = Array(repeating: 0, count: Globals.BOARD_SIZE)
        self.history = []
    }

    init(given: [Int8]) {
        self.given = given
        self.solved = given
        self.history = []
    }

    init(given: [Int8], solved: [Int8]) {
        self.given = given
        self.solved = solved
        self.history = []
    }

    init(given: [Int8], solved: [Int8], history: [HistoryItem]) {
        self.given = given
        self.solved = solved
        self.history = history
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.given = try container.decode(Array<Int8>.self, forKey: .given)
        self.solved = try container.decode(Array<Int8>.self, forKey: .solved)
        self.history = try container.decode(Array<HistoryItem>.self, forKey: .history)
    }

    convenience init(from puzzleString: String) {
        if (puzzleString.count > Globals.BOARD_SIZE) {
            fatalError("Error: Sudoku size too large")
        }

        var sudoku: [Int8] = Array(repeating: 0, count: Globals.BOARD_SIZE)

        for (index, char) in puzzleString.enumerated() {
            let num = Int8(String(char)) ?? -1
            if (num < 0 || num > Globals.BLOCK_SIZE) {
                fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(char), must be 0-\(Globals.BLOCK_SIZE)")
            }

            sudoku[index] = num
        }

        self.init(given: sudoku)
    }
}

func sudokuUtils(undoMoveFrom sudoku: Sudoku) -> Bool {
    // Try to pop last history item:
    if let move = sudoku.history.popLast() {

        // Check if we have earlier history on the same position
        if let item = (sudoku.history.reversed().first {item in
            return item.position == move.position
        }) {
            debugPrint("Found earlier value in same cell: \(sudoku.solved[move.position]) -> \(item.number)")
            // Replace the number with earlier value
            sudoku.solved[move.position] = item.number
        } else {
            // No earlier value, clear it
            sudoku.solved[move.position] = 0
        }
        return true
    }

    return false
}

func sudokuUtils(addMove move: Sudoku.HistoryItem, to sudoku: Sudoku) -> Bool {
    if sudoku.given[move.position] == 0 && sudoku.solved[move.position] != move.number {
        sudoku.solved[move.position] = move.number
        sudoku.history.append(move)
        return true
    }
    return false
}

func sudokuUtils(hasMovesInHistory sudoku: Sudoku) -> Bool {
    return !sudoku.history.isEmpty
}

func debugPrint(_ message: String) {
    if Globals.DEBUG_PRINT_ENABLED {
        print(message)
    }
}
