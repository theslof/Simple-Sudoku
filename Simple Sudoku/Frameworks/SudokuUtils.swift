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
    static let SEC_WIDTH = 3
    static let ROW_SIZE = SEC_WIDTH * SEC_WIDTH
    static let BOARD_SIZE = ROW_SIZE * ROW_SIZE
    static let SUDOKU_SELL_REUSABLE_ID = "sudoku_cell"
    static let DEBUG_PRINT_ENABLED = true
}

/**
Sudoku puzzle as a swift class, complete with methods for manipulating the cell values.
*/
class Sudoku: Codable {
    private(set) var solutions: Int = 0
    private(set) var guesses: Int = 0
    private(set) var seed: UInt64
    private(set) var difficulty: String = "Unknown"
    var given: [Int]
    var solved: [Int]
    var history: [HistoryItem]
    var solution: [Int]?

    // Helper arrays, speeds up solving drastically
    private var rows: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var cols: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var secs: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var randomOrder: [Int] = Array(0..<Globals.BOARD_SIZE)

    static let rowIndices: [Int] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                     1, 1, 1, 1, 1, 1, 1, 1, 1,
                                     2, 2, 2, 2, 2, 2, 2, 2, 2,
                                     3, 3, 3, 3, 3, 3, 3, 3, 3,
                                     4, 4, 4, 4, 4, 4, 4, 4, 4,
                                     5, 5, 5, 5, 5, 5, 5, 5, 5,
                                     6, 6, 6, 6, 6, 6, 6, 6, 6,
                                     7, 7, 7, 7, 7, 7, 7, 7, 7,
                                     8, 8, 8, 8, 8, 8, 8, 8, 8 ]
    static let colIndices: [Int] = [ 0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8,
                                     0, 1, 2, 3, 4, 5, 6, 7, 8 ]
    static let secIndices: [Int] = [ 0, 0, 0, 1, 1, 1, 2, 2, 2,
                                     0, 0, 0, 1, 1, 1, 2, 2, 2,
                                     0, 0, 0, 1, 1, 1, 2, 2, 2,
                                     3, 3, 3, 4, 4, 4, 5, 5, 5,
                                     3, 3, 3, 4, 4, 4, 5, 5, 5,
                                     3, 3, 3, 4, 4, 4, 5, 5, 5,
                                     6, 6, 6, 7, 7, 7, 8, 8, 8,
                                     6, 6, 6, 7, 7, 7, 8, 8, 8,
                                     6, 6, 6, 7, 7, 7, 8, 8, 8 ]
    //var seed: UInt64

    struct HistoryItem: Codable {
        var position: Int
        var number: Int
    }

    private enum CodingKeys: String, CodingKey {
        case given
        case solved
        case history
        case seed
    }

    //######################
    // MARK: - Initializers
    //######################

    convenience init() {
        self.init(given: Array(repeating: 0, count: Globals.BOARD_SIZE))
    }

    convenience init(given: [Int]) {
        self.init(given: given, solved: given)
    }

    convenience init(given: [Int], solved: [Int]) {
        self.init(given: given, solved: solved, history: [])
    }

    convenience init(qqwing: QQWing) {
        self.init(given: qqwing.getPuzzle())
        self.seed = qqwing.seed
        switch qqwing.getDifficultyAsString() {
        case "Easy":
            self.difficulty = "Easy"
        case "Intermediate":
            self.difficulty = "Medium"
        case "Expert":
            self.difficulty = "Hard"
        default:
            break
        }
    }

    init(given: [Int], solved: [Int], history: [HistoryItem]) {
        self.seed = UInt64(time(nil))
        self.given = given
        self.solved = solved
        self.history = history
        clearIllegalValues()
        loadHelperArrays()
    }


    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.given = try container.decode(Array<Int>.self, forKey: .given)
        self.solved = try container.decode(Array<Int>.self, forKey: .solved)
        self.history = try container.decode(Array<HistoryItem>.self, forKey: .history)
        self.seed = try container.decode(UInt64.self, forKey: .seed)
        clearIllegalValues()
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

    func clearIllegalValues() {
        for i in (0..<Globals.BOARD_SIZE) {
            if self.given[i] < 0 || self.given[i] > Globals.ROW_SIZE { self.given[i] = 0 }
            if self.solved[i] < 0 || self.solved[i] > Globals.ROW_SIZE { self.solved[i] = 0 }
        }
        for (i, v) in self.history.enumerated() {
            if v.number < 0 || v.number > Globals.ROW_SIZE { self.history.remove(at: i) }
        }
    }

    // Initialize our helper arrays
    private func loadHelperArrays() {
        for (index, c) in self.solved.enumerated() {
            if c != 0 {
                self.rows[Sudoku.rowIndices[index]][c - 1] += 1
                self.cols[Sudoku.colIndices[index]][c - 1] += 1
                self.secs[Sudoku.secIndices[index]][c - 1] += 1
            }
        }
    }

    //#####################
    // MARK: -Manipulation
    //#####################

    // Attempt to add a legal move at specified cell. Returns false if it's illegal.
    func addLegal(move: HistoryItem, log: Bool) -> Bool {
        if ( rows[Sudoku.rowIndices[move.position]][move.number - 1] > 0 ||
             cols[Sudoku.colIndices[move.position]][move.number - 1] > 0 ||
             secs[Sudoku.secIndices[move.position]][move.number - 1] > 0 ) {
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
            self.secs[Sudoku.secIndices[move.position]][old - 1] -= 1
        }
        if (move.number != 0) {
            // We are adding a new value and should increase the helper arrays accordingly
            self.rows[Sudoku.rowIndices[move.position]][move.number - 1] += 1
            self.cols[Sudoku.colIndices[move.position]][move.number - 1] += 1
            self.secs[Sudoku.secIndices[move.position]][move.number - 1] += 1
        }

        // Write the new value to the puzzle array
        self.solved[move.position] = move.number

        if (log) {
            self.history.append(move)
        }
    }

    /*********
    * Solver *
    *********/

    // Solve the puzzle without specifying a seed
    func solve() -> Int {
        return self.solve(withRandomSeed: UInt64(time(nil)))
    }

    // Solve the puzzle with the supplied seed for the random generator
    func solve(withRandomSeed seed: UInt64) -> Int {
        let rs = GKMersenneTwisterRandomSource()
        rs.seed = seed
        self.solutions = 0
        self.guesses = 0
        self.solution = nil
        self.randomOrder = shuffle(array: Array(0..<Globals.BOARD_SIZE), randomSource: rs)
        self.solve(randomSource: rs, next: 0)
        return self.solutions
    }

    // The solver algorithm, recursively loops through each cell and checks all possible solutions.
    // Only the latest found solution is saved.
    private func solve(randomSource rs: GKMersenneTwisterRandomSource, next i: Int) {
        if( i >= self.solved.count) {
            // We have filled the entire sudoku, and it must be legal.

            // Save the last found solution
            self.solution = self.solved
            // Increase solution counter by one
            self.solutions += 1

            // Backtrack
            return
        }
        // Take next index from our array of a predefined random order:
        let currentCell = self.randomOrder[i]
        if( self.solved[currentCell] == 0 ) {
            // The current cell is unsolved

            // Try to solve the cell for number [1...9] in a random order:
            let numbers: [Int] = shuffle(array: Array(1...Globals.ROW_SIZE), randomSource: rs)
            for n in numbers {
                // Since we're brute forcing everything's a guess, but we still track it
                self.guesses += 1

                // Try to add the move
                if ( self.addLegal(move: HistoryItem(position: currentCell, number: n), log: false) ) {

                    // Move was legal, solve next unsolved cell
                    self.solve(randomSource: rs, next: i+1)

                    // Clear the cell and check next value for a solution
                    self.add(move: HistoryItem(position: currentCell, number: 0), log: false)
                }
            }

            // No solution found for this cell, there must be an error earlier in the sudoku. Backtrack.
            return
        }

        // This cell was already filled in, try the next cell instead
        self.solve(randomSource: rs, next: i+1)
    }

    // Shuffle the array using the supplied random source
    func shuffle(array: [Int], randomSource rs: GKMersenneTwisterRandomSource) -> [Int] {
        var original = array
        var shuffled: [Int] = []
        let rand = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: original.count)

        while original.count > 0 {
            shuffled.append(original.remove(at: rand.nextInt(upperBound: original.count)))
        }

        return shuffled
    }

    // Check if the puzzle is solved. If the .solved array does not contain 0 it has no unknowns and is solved.
    func isSolved() -> Bool {
        return !self.solved.contains(0)
    }

    // Check if the puzzle is legal, ie. has no duplicates in any row, column or section. Thanks to our helper arrays
    // we can simply check that no row/cel/sec has more than one of each value.
    func isLegal() -> Bool {
        for i in 0..<Globals.ROW_SIZE {
            for j in 0..<Globals.ROW_SIZE {
                if self.rows[i][j] > 1 || self.cols[i][j] > 1 || self.secs[i][j] > 1 {
                    return false
                }

            }
        }
        return true
    }
}

//###########
// Utilities
//###########

// Return the row that matches the cell number
func sudokuUtils(findRowForCell cell: Int) -> Int {
    return Sudoku.rowIndices[cell]
}

// Return the column that matches the cell number
func sudokuUtils(findColForCell cell: Int) -> Int {
    return Sudoku.colIndices[cell]
}

// Return the section that matches the cell number
func sudokuUtils(findSecForCell cell: Int) -> Int {
    return Sudoku.secIndices[cell]
}

// Undo latest move from the specified sudoku puzzle. Returns true if successful.
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

// Add a new move to the puzzle. Return true if successful.
func sudokuUtils(addMove move: Sudoku.HistoryItem, to sudoku: Sudoku) -> Bool {
    if move.number >= 0 && move.number <= Globals.ROW_SIZE && sudoku.given[move.position] == 0 && sudoku.solved[move.position] != move.number {
        sudoku.solved[move.position] = move.number
        sudoku.history.append(move)
        return true
    }
    return false
}

// Check if we have any moves in our move history.
func sudokuUtils(hasMovesInHistory sudoku: Sudoku) -> Bool {
    return !sudoku.history.isEmpty
}

/// Print out a message if debug is enabled, otherwise ignore. Set Globals.DEBUG_PRINT_ENABLED to false to disable debug messages.
func debugPrint(_ message: String) {
    if Globals.DEBUG_PRINT_ENABLED {
        print(message)
    }
}
