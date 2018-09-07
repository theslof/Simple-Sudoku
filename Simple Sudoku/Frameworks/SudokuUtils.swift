//
//  SudokuUtils.?s?wift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-03.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation
import GameKit

struct Globals {
    static let BLOCK_WIDTH = 3
    static let ROW_SIZE = BLOCK_WIDTH * BLOCK_WIDTH
    static let BOARD_SIZE = ROW_SIZE * ROW_SIZE
    static let SUDOKU_SELL_REUSABLE_ID = "sudoku_cell"
    static let DEBUG_PRINT_ENABLED = true
}

class Sudoku: Codable {
    var given: [Int]
    var solved: [Int]
    var history: [HistoryItem]
    private var rows: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var cols: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var blocks: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    static let rowIndices: [Int] = Array(0..<Globals.BOARD_SIZE).flatMap { i in Array(repeating: i, count: Globals.ROW_SIZE) }
    static let colIndices: [Int] = Array(0..<Globals.BOARD_SIZE).flatMap { i in Array(0..<Globals.ROW_SIZE) }
    // TODO: Fix this, it's awful
    static let blockIndices: [Int] = [ 0, 0, 0, 1, 1, 1, 2, 2, 2,
                                       0, 0, 0, 1, 1, 1, 2, 2, 2,
                                       0, 0, 0, 1, 1, 1, 2, 2, 2,
                                       3, 3, 3, 4, 4, 4, 5, 5, 5,
                                       3, 3, 3, 4, 4, 4, 5, 5, 5,
                                       3, 3, 3, 4, 4, 4, 5, 5, 5,
                                       6, 6, 6, 7, 7, 7, 8, 8, 8,
                                       6, 6, 6, 7, 7, 7, 8, 8, 8,
                                       6, 6, 6, 7, 7, 7, 8, 8, 8]
    //var seed: UInt64

    struct HistoryItem: Codable {
        var position: Int
        var number: Int
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
        loadHelperArrays()
    }

    init(given: [Int]) {
        self.given = given
        self.solved = given
        self.history = []
        loadHelperArrays()
    }

    init(given: [Int], solved: [Int]) {
        self.given = given
        self.solved = solved
        self.history = []
        loadHelperArrays()
    }

    init(given: [Int], solved: [Int], history: [HistoryItem]) {
        self.given = given
        self.solved = solved
        self.history = history
        loadHelperArrays()
    }


    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.given = try container.decode(Array<Int>.self, forKey: .given)
        self.solved = try container.decode(Array<Int>.self, forKey: .solved)
        self.history = try container.decode(Array<HistoryItem>.self, forKey: .history)
        loadHelperArrays()
    }

    // Initialize the sudoku from a string
    convenience init(from puzzleString: String) {
        if (puzzleString.count > Globals.BOARD_SIZE) {
            fatalError("Error: Sudoku size too large")
        }

        var sudoku: [Int] = Array(repeating: 0, count: Globals.BOARD_SIZE)

        for (index, char) in puzzleString.enumerated() {
            let num = Int(String(char)) ?? -1
            if (num < 0 || num > Globals.ROW_SIZE) {
                fatalError("Error: Sudoku cell value at position \(index) invalid! Was \(char), must be 0-\(Globals.ROW_SIZE)")
            }

            sudoku[index] = num
        }

        self.init(given: sudoku)
    }

    // Initialize our helper arrays
    private func loadHelperArrays() {
        for (index, c) in self.solved.enumerated() {
            if c != 0 {
                self.rows[Sudoku.rowIndices[index]][c - 1] += 1
                self.cols[Sudoku.colIndices[index]][c - 1] += 1
                self.blocks[Sudoku.blockIndices[index]][c - 1] += 1
            }
        }
    }

    // Attempt to add a legal move at specified cell. Returns false if it's illegal.
    func addLegal(move: HistoryItem, log: Bool) -> Bool {
        if ( rows[Sudoku.rowIndices[move.position]][move.number - 1] > 0 ||
             cols[Sudoku.colIndices[move.position]][move.number - 1] > 0 ||
             blocks[Sudoku.blockIndices[move.position]][move.number - 1] > 0 ) {
            return false
        }

        add(move: move, log: log)
        return true
    }

    // Forcefully add a move at the specified cell, adding it to move history if log is true
    func add(move: HistoryItem, log: Bool){
        // First we want to update the helper arrays:
        let old = self.solved[move.position]
        if (old != 0) {
            // We're overwriting an existing value and need to reflect this in the helper arrays by decreasing the
            // relevant values:
            self.rows[Sudoku.rowIndices[move.position]][old - 1] -= 1
            self.cols[Sudoku.colIndices[move.position]][old - 1] -= 1
            self.blocks[Sudoku.blockIndices[move.position]][old - 1] -= 1
        }
        if (move.number != 0) {
            // We are adding a new value and should increase the helper arrays accordingly
            self.rows[Sudoku.rowIndices[move.position]][move.number - 1] += 1
            self.cols[Sudoku.colIndices[move.position]][move.number - 1] += 1
            self.blocks[Sudoku.blockIndices[move.position]][move.number - 1] += 1
        }

        // Write the new value to the puzzle array
        self.solved[move.position] = move.number

        if (log) {
            self.history.append(move)
        }
    }
}

func sudokuUtils(findRowForCell cell: Int) -> Int {
    return Sudoku.rowIndices[cell]
}

func sudokuUtils(findColForCell cell: Int) -> Int {
    return Sudoku.colIndices[cell]
}

func sudokuUtils(findBlockForCell cell: Int) -> Int {
    return Sudoku.blockIndices[cell]
}

func sudokuUtils(undoMoveFrom sudoku: Sudoku) -> Bool {
    // Try to pop last history item:
    if let move = sudoku.history.popLast() {

        // Check if we have earlier history on the same position, otherwise clear it
        let item: Sudoku.HistoryItem = sudoku.history.reversed().first {item in
            return item.position == move.position
        } ?? Sudoku.HistoryItem(position: move.position, number: 0)

        sudoku.add(move: item, log: false)
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

func sudokuUtils(solve: Sudoku) -> Bool{
    return false
}

// #############
// # Generator #
// #############

func sudokuUtils(generateSudoku sudoku: Sudoku) -> Bool {
    return sudokuUtils(generateSudoku: sudoku, fromSeed: UInt64(time(nil)))
}

func sudokuUtils(generateSudoku sudoku: Sudoku, fromSeed seed: UInt64) -> Bool {
    let rs = GKMersenneTwisterRandomSource()
    rs.seed = seed
    return sudokuGenerator(sudoku: sudoku, randomSource: rs, next: 0)
}

private func sudokuGenerator(sudoku: Sudoku, randomSource rs: GKMersenneTwisterRandomSource, next i: Int) -> Bool {
    if( i >= sudoku.solved.count) {
        // We have filled the entire sudoku, and it must be legal.
        return true
    } else if( sudoku.solved[i] == 0 ) {
        // The current cell is unsolved
        let numbers: [Int] = shuffledNumbers(rs)

        // Try to solve the cell for number [1...9] in a random order:
        for n in numbers {

            // Try to add the move
            if ( sudoku.addLegal(move: Sudoku.HistoryItem(position: i, number: n), log: false) ) {

                // Move was legal, solve next unsolved cell
                if ( sudokuGenerator(sudoku: sudoku, randomSource: rs, next: i+1) ) {
                    // Next cell returned True, which means that the sudoku is solved and legal
                    return true
                }

                // We failed to solve the rest of the sudoku, clear the cell
                sudoku.add(move: Sudoku.HistoryItem(position: i, number: 0), log: false)
            }
            debugPrint("Move \(n) at cell \(i) was illegal.")
        }

        // No solution found for this cell, there must be an error earlier in the sudoku. Backtrack.
        return false
    }
    return sudokuGenerator(sudoku: sudoku, randomSource: rs, next: i+1)
}

private func shuffledNumbers(_ rs: GKMersenneTwisterRandomSource) -> [Int] {
    var unshuffled: [Int] = Array(1...Globals.ROW_SIZE)
    var nums: [Int] = []
    let rand = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: unshuffled.count)

    while unshuffled.count > 0 {
        nums.append(unshuffled.remove(at: rand.nextInt(upperBound: unshuffled.count)))
    }

    return nums
}


/// Print out a message if debug is enabled, otherwise ignore. Set Globals.DEBUG_PRINT_ENABLED to false to disable debug messages.
func debugPrint(_ message: String) {
    if Globals.DEBUG_PRINT_ENABLED {
        print(message)
    }
}
