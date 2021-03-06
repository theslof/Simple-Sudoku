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
    private(set) var seed: UInt64
    private(set) var difficulty: String = "Unknown"
    private(set) var symmetry: String = "None"
    var given: [Int]
    var solved: [Int]
    var history: [HistoryItem]

    // Helper arrays, speeds up solving drastically
    private var rows: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var cols: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
    private var secs: [[Int]] = Array(repeating: Array(repeating: 0, count: Globals.ROW_SIZE), count: Globals.ROW_SIZE)
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

    struct HistoryItem: Codable {
        var position: Int
        var number: Int
    }

    private enum CodingKeys: String, CodingKey {
        case given
        case solved
        case history
        case seed
        case difficulty
        case symmetry
    }

    //######################
    // MARK: - Initializers
    //######################

    /// Initialize an empty sudoku
    convenience init() {
        self.init(given: Array(repeating: 0, count: Globals.BOARD_SIZE))
    }

    /// Initialize a sudoku from only given values
    convenience init(given: [Int]) {
        self.init(given: given, solved: given)
    }

    /// Initialize a sudoku from both given and solved values
    convenience init(given: [Int], solved: [Int]) {
        self.init(given: given, solved: solved, history: [])
    }

    /// Initialize a sudoku from a QQWing object
    convenience init(qqwing: QQWing) {
        self.init(given: qqwing.getPuzzle())
        self.seed = qqwing.seed
        switch qqwing.getDifficulty() {
        case .EASY:
            self.difficulty = "Easy"
        case .INTERMEDIATE:
            self.difficulty = "Medium"
        case .EXPERT:
            self.difficulty = "Hard"
        default:
            break
        }
        switch qqwing.symmetry {
        case Symmetry.ROTATE180:
            self.symmetry = "Rotate 180"
        case Symmetry.ROTATE90:
            self.symmetry = "Rotate 90"
        case Symmetry.FLIP:
            self.symmetry = "Flip"
        case Symmetry.MIRROR:
            self.symmetry = "Mirror"
        default:
            break
        }
    }

    /// Initialize the sudoku from arrays of given, solved and history
    init(given: [Int], solved: [Int], history: [HistoryItem]) {
        self.seed = randomSeed
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
        self.difficulty = try container.decode(String.self, forKey: .difficulty)
        self.symmetry = try container.decode(String.self, forKey: .symmetry)
        clearIllegalValues()
        loadHelperArrays()
    }

    /// Initialize the sudoku from a string
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

    /// Check the puzzle and remove any illegal values.
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

    /// Attempt to add a legal move at specified cell. Returns false if it's illegal.
    func addLegal(move: HistoryItem, log: Bool) -> Bool {
        if ( rows[Sudoku.rowIndices[move.position]][move.number - 1] > 0 ||
             cols[Sudoku.colIndices[move.position]][move.number - 1] > 0 ||
             secs[Sudoku.secIndices[move.position]][move.number - 1] > 0 ) {
            return false
        }

        add(move: move, log: log)
        return true
    }

    /**
     * Forcefully add a move at the specified cell
     * - parameters:
     *   - move: The move in the form of a HistoryItem
     *   - log: Add the move to move history if true
     */
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
    * Checks *
    *********/

    struct Error {
        let first: Int
        let second: Int
    }

    /// Returns a list of Errors in the sudoku
    func getErrors() -> [Sudoku.Error] {
        var errors: [Sudoku.Error] = []

        // Find all rows where any number is represented more than once. Run them through findConflictsIn(row:) and
        // append the errors to our error array.
        errors.append(contentsOf: rows.enumerated().flatMap { (index, row) -> [Sudoku.Error] in
            if (row.contains { i in i > 1 }) {
                return findConflictsIn(row: index)
            }
            return []
        })

        errors.append(contentsOf: cols.enumerated().flatMap { (index, col) -> [Sudoku.Error] in
            if (col.contains { i in i > 1 }) {
                return findConflictsIn(col: index)
            }
            return []
        })

        errors.append(contentsOf: secs.enumerated().flatMap { (index, sec) -> [Sudoku.Error] in
            if (sec.contains { i in i > 1 }) {
                return findConflictsIn(sec: index)
            }
            return []
        })

        var filteredErrors:[Sudoku.Error] = []

        errors.forEach { error in
            if !filteredErrors.contains(where: { e in error.first == e.first && error.second == e.second }) {
                filteredErrors.append(error)
            }
        }

        return filteredErrors
    }

    private func findConflictsIn(row i: Int) -> [Sudoku.Error] {
        var errors: [Sudoku.Error] = []
        let start = Sudoku.firstPosIn(row: i)
        let row:[Int] = Array(solved[start..<start+Globals.ROW_SIZE])
        debugPrint("Row \(i): \(row)")

        for (a, b) in findConflictsIn(array: row) {
            errors.append(Error(
                    first: Sudoku.localToGlobal(row: i, offset: a),
                    second: Sudoku.localToGlobal(row: i, offset: b)))
        }

        return errors
    }

    private func findConflictsIn(col i: Int) -> [Sudoku.Error] {
        var errors: [Sudoku.Error] = []
        var col:[Int] = []

        for c in 0..<Globals.ROW_SIZE {
            col.append(solved[Sudoku.localToGlobal(col: i, offset: c)])
        }

        debugPrint("Column \(i): \(col)")

        for (a, b) in findConflictsIn(array: col) {
            errors.append(Error(
                    first: Sudoku.localToGlobal(col: i, offset: a),
                    second: Sudoku.localToGlobal(col: i, offset: b)))
        }

        return errors
    }

    private func findConflictsIn(sec i: Int) -> [Sudoku.Error] {
        var errors: [Sudoku.Error] = []
        var sec:[Int] = []

        for s in 0..<Globals.ROW_SIZE {
            sec.append(solved[Sudoku.localToGlobal(sec: i, offset: s)])
        }
        debugPrint("Section \(i): \(sec)")

        for (a, b) in findConflictsIn(array: sec) {
            errors.append(Error(
                    first: Sudoku.localToGlobal(sec: i, offset: a),
                    second: Sudoku.localToGlobal(sec: i, offset: b)))
        }

        return errors
    }

    private func findConflictsIn(array: [Int]) -> [(Int, Int)] {
        var errors: [(Int, Int)] = []

        for i in 0..<array.count {
            if array[i] == 0 { continue }
            for j in (i+1)..<array.count {
                if array[j] == 0 { continue }
                if array[i] == array[j] {
                    errors.append((i, j))
//                    break
                }
            }
        }

        return errors
    }

    func getProgress() -> Int {
        var progress: Int = 0
        for i in solved {
            if i != 0 {
                progress += 1
            }
        }
        return progress
    }

    /// Returns true if the puzzle is solved.
    func isSolved() -> Bool {
        // If the .solved array does not contain 0 it has no unknowns and is solved.
        return !self.solved.contains(0)
    }

    /// Check if the puzzle is legal, ie. has no duplicates in any row, column or section.
    func isLegal() -> Bool {
        // Thanks to our helper arrays we can simply check that no row/cel/sec has more than one of each value.
        for i in 0..<Globals.ROW_SIZE {
            for j in 0..<Globals.ROW_SIZE {
                if self.rows[i][j] > 1 || self.cols[i][j] > 1 || self.secs[i][j] > 1 {
                    return false
                }

            }
        }
        return true
    }

    // Helpers

    private static func firstPosIn(row: Int) -> Int {
        return row * Globals.ROW_SIZE
    }

    private static func firstPosIn(col: Int) -> Int {
        return col
    }

    private static func firstPosIn(sec: Int) -> Int {
        let secRow = sec / Globals.SEC_WIDTH
        let secCol = sec % Globals.SEC_WIDTH
        return secRow * Globals.SEC_WIDTH * Globals.ROW_SIZE + secCol * Globals.SEC_WIDTH
    }

    private static func localToGlobal(row: Int, offset: Int) -> Int {
        return firstPosIn(row: row) + offset
    }

    private static func localToGlobal(col: Int, offset: Int) -> Int {
        return firstPosIn(col: col) + offset * Globals.ROW_SIZE
    }

    private static func localToGlobal(sec: Int, offset: Int) -> Int {
        let offsetRow = offset / Globals.SEC_WIDTH
        let offsetCol = offset % Globals.SEC_WIDTH
        return firstPosIn(sec: sec) + offsetRow * Globals.ROW_SIZE + offsetCol
    }
}

//###########
// Utilities
//###########

/// Return the row that matches the cell number
func sudokuUtils(findRowForCell cell: Int) -> Int {
    return Sudoku.rowIndices[cell]
}

/// Return the column that matches the cell number
func sudokuUtils(findColForCell cell: Int) -> Int {
    return Sudoku.colIndices[cell]
}

/// Return the section that matches the cell number
func sudokuUtils(findSecForCell cell: Int) -> Int {
    return Sudoku.secIndices[cell]
}

/// Undo latest move from the specified sudoku puzzle. Returns true if successful.
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

/// Add a new move to the puzzle. Return true if successful.
func sudokuUtils(addMove move: Sudoku.HistoryItem, to sudoku: Sudoku) -> Bool {
    if move.number >= 0 && move.number <= Globals.ROW_SIZE && sudoku.given[move.position] == 0 && sudoku.solved[move.position] != move.number {
        sudoku.add(move: move, log: true)
        return true
    }
    return false
}

/// Check if we have any moves in our move history.
func sudokuUtils(hasMovesInHistory sudoku: Sudoku) -> Bool {
    return !sudoku.history.isEmpty
}

/// Print out a message if debug is enabled, otherwise ignore. Set Globals.DEBUG_PRINT_ENABLED to false to disable debug messages.
func debugPrint(_ message: String) {
    if Globals.DEBUG_PRINT_ENABLED {
        print(message)
    }
}

/// Contains a new random seed, generated every time it's used
var randomSeed: UInt64 {
    // Generate from two random UInt32: Bitshift the first 32 to the left and OR it with the second.
    return UInt64(arc4random()) << 32 | UInt64(arc4random())
}

func BQ(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

func MQ(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

func errorColorFor(number: Int) -> UIColor {
    return UIColor(hue: CGFloat(number) / CGFloat(Globals.ROW_SIZE), saturation: 1, brightness: 1, alpha: 1)
}
