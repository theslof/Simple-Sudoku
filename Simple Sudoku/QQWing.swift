/*
 * qqwing - Sudoku solver and generator
 * Copyright (C) 2006-2014 Stephen Ostermiller http://ostermiller.org/
 * Copyright (C) 2007 Jacques Bensimon (jacques@ipm.com)
 * Copyright (C) 2007 Joel Yarde (joel.yarde - gmail.com)
 * Ported from Java to Swift in 2018 by Jonas Theslöf
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import Foundation
import GameKit

public enum Action {
    case NONE
    case GENERATE
    case SOLVE
}

public enum Difficulty: String {
    case UNKNOWN = "Unknown"
    case SIMPLE = "Simple"
    case EASY = "Easy"
    case INTERMEDIATE = "Intermediate"
    case EXPERT = "Expert"
}

public enum Symmetry {
    case NONE
    case ROTATE90
    case ROTATE180
    case MIRROR
    case FLIP
    case RANDOM
}

public enum PrintStyle {
    case ONE_LINE
    case COMPACT
    case READABLE
    case CSV
}

/**
 * While solving the puzzle, log steps taken in a log item. This is useful for
 * later printing out the solve history or gathering statistics about how hard
 * the puzzle was to solve.
 */
public class LogItem: CustomStringConvertible {
    /**
     * The recursion level at which this item was gathered. Used for backing out
     * log items solve branches that don't lead to a solution.
     */
    let round: Int

    /**
     * The type of log message that will determine the message printed.
     */
    let type: LogType

    /**
     * Value that was set by the operation (or zero for no value)
     */
    private var _value: Int = 0
    var value: Int {
        get {
            return (self._value <= 0) ? -1 : self._value
        }
        set {
            self._value = value
        }
    }

    /**
     * position on the board at which the value (if any) was set.
     */
    let position: Int

    public var description: String {
        var sb: String = ""
        sb.append("Round: ")
        sb.append(String(round))
        sb.append(" - ")
        sb.append(type.getDescription())
        if (value > 0 || position > -1) {
            sb.append(" (")
            if (position > -1) {
                sb.append("Row: ")
                sb.append(String(getRow()))
                sb.append(" - Column: ")
                sb.append(String(getColumn()))
            }
            if (value > 0) {
                if (position > -1) { sb.append(" - ") }
                sb.append("Value: ")
                sb.append(String(getValue()))
            }
            sb.append(")")
        }
        return sb
    }

    convenience init(_ r: Int, _ t: LogType) {
        self.init(r, t, 0, -1)
    }

    init(_ r: Int, _ t: LogType, _ v: Int, _ p: Int) {
        self.round = r
        self.type = t
        self.position = p
        self.value = v
    }

    /**
     * Get the row (1 indexed), or -1 if no row
     */
    func getRow() -> Int {
        return (position <= -1) ? -1 : QQWing.cellToRow(position) + 1
    }

    /**
     * Get the column (1 indexed), or -1 if no column
     */
    func getColumn() -> Int {
        return (position <= -1) ? -1 : QQWing.cellToColumn(position) + 1
    }

    /**
     * Get the value, or -1 if no value
     */
    func getValue() -> Int {
        return (value <= 0) ? -1 : value
    }
}

public enum LogType: String {
    case GIVEN = "Mark given"
    case SINGLE = "Mark only possibility for cell"
    case HIDDEN_SINGLE_ROW = "Mark single possibility for value in row"
    case HIDDEN_SINGLE_COLUMN = "Mark single possibility for value in column"
    case HIDDEN_SINGLE_SECTION = "Mark single possibility for value in section"
    case GUESS = "Mark guess  = start round)"
    case ROLLBACK = "Roll back round"
    case NAKED_PAIR_ROW = "Remove possibilities for naked pair in row"
    case NAKED_PAIR_COLUMN = "Remove possibilities for naked pair in column"
    case NAKED_PAIR_SECTION = "Remove possibilities for naked pair in section"
    case POINTING_PAIR_TRIPLE_ROW = "Remove possibilities for row because all values are in one section"
    case POINTING_PAIR_TRIPLE_COLUMN = "Remove possibilities for column because all values are in one section"
    case ROW_BOX = "Remove possibilities for section because all values are in one row"
    case COLUMN_BOX = "Remove possibilities for section because all values are in one column"
    case HIDDEN_PAIR_ROW = "Remove possibilities from hidden pair in row"
    case HIDDEN_PAIR_COLUMN = "Remove possibilities from hidden pair in column"
    case HIDDEN_PAIR_SECTION = "Remove possibilities from hidden pair in section"

    func getDescription() -> String {
        return self.rawValue;
    }
}

/**
 * The board containing all the memory structures and methods for solving or
 * generating sudoku puzzles.
 */
public class QQWing {
    static let QQWING_VERSION: String = "1.3.4"
    static let NL: String = "\r\n"
    static let GRID_SIZE: Int = 3
    static let ROW_COL_SEC_SIZE: Int = (GRID_SIZE * GRID_SIZE)
    static let SEC_GROUP_SIZE: Int = (ROW_COL_SEC_SIZE * GRID_SIZE)
    static let BOARD_SIZE: Int = (ROW_COL_SEC_SIZE * ROW_COL_SEC_SIZE)
    static let POSSIBILITY_SIZE: Int = (BOARD_SIZE * ROW_COL_SEC_SIZE)
    private var random: GKRandomDistribution
    private(set) var seed: UInt64

    /**
     * The last round of solving
     */
    private var lastSolveRound: Int = 0

    /**
     * The 81 integers that make up a sudoku puzzle. Givens are 1-9, unknowns
     * are 0. Once initialized, this puzzle remains as is. The answer is worked
     * out in "solution".
     */
    private var puzzle: [Int] = Array(repeating: 0, count: BOARD_SIZE)

    /**
     * The 81 integers that make up a sudoku puzzle. The solution is built here,
     * after completion all will be 1-9.
     */
    private var solution: [Int] = Array(repeating: 0, count: BOARD_SIZE)

    /**
     * Recursion depth at which each of the numbers in the solution were placed.
     * Useful for backing out solve branches that don't lead to a solution.
     */
    private var solutionRound: [Int] = Array(repeating: 0, count: BOARD_SIZE)

    /**
     * The 729 integers that make up a the possible values for a Sudoku puzzle.
     * (9 possibilities for each of 81 squares). If possibilities[i] is zero,
     * then the possibility could still be filled in according to the Sudoku
     * rules. When a possibility is eliminated, possibilities[i] is assigned the
     * round (recursion level) at which it was determined that it could not be a
     * possibility.
     */
    private var possibilities: [Int] = Array(repeating: 0, count: POSSIBILITY_SIZE)

    /**
     * An array the size of the board (81) containing each of the numbers 0-n
     * exactly once. This array may be shuffled so that operations that need to
     * look at each cell can do so in a random order.
     */
    private var randomBoardArray: [Int] = fillIncrementing(BOARD_SIZE)

    /**
     * An array with one element for each position (9), in some random order to
     * be used when trying each position in turn during guesses.
     */
    private var randomPossibilityArray: [Int] = fillIncrementing(ROW_COL_SEC_SIZE)

    /**
     * Whether or not to record history
     */
    private var recordHistory: Bool = false;

    /**
     * Whether or not to print history as it happens
     */
    private var logHistory: Bool = false;

    /**
     * A list of moves used to solve the puzzle. This list contains all moves,
     * even on solve branches that did not lead to a solution.
     */
    private var solveHistory: [LogItem] = []

    /**
     * A list of moves used to solve the puzzle. This list contains only the
     * moves needed to solve the puzzle, but doesn't contain information about
     * bad guesses.
     */
    private var solveInstructions: [LogItem] = []

    /**
     * The style with which to print puzzles and solutions
     */
    private var printStyle: PrintStyle = PrintStyle.READABLE

    /**
    * The symmetry of the puzzle
    */
    private(set) var symmetry: Symmetry = Symmetry.NONE

    /**
     * Create a new Sudoku board
     * If a seed is supplied we should expect the same outcome every time
     */
    convenience init() {
        self.init(UInt64(time(nil)))
    }

    init(_ seed: UInt64) {
        self.seed = seed
        let rs = GKMersenneTwisterRandomSource(seed: seed)
        random = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: 80)
    }

    func setSeed(_ seed: UInt64){
        self.seed = seed
        let rs = GKMersenneTwisterRandomSource(seed: seed)
        random = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: 80)
    }

    private static func fillIncrementing(_ size: Int) -> [Int] {
        let new: [Int] = Array(0..<size)
        return new
    }

    /**
     * Get the number of cells that are set in the puzzle (as opposed to figured
     * out in the solution
     */
    public func getGivenCount() -> Int {
        var count: Int = 0;
        for i in puzzle {
            count += i != 0 ? 1 : 0
        }
        return count;
    }

    /**
     * Set the board to the given puzzle. The given puzzle must be an array of
     * 81 integers.
     */
    public func setPuzzle(_ initPuzzle: [Int]?) -> Bool {
        for i in (0..<QQWing.BOARD_SIZE) {
            puzzle[i] = initPuzzle?[i] ?? 0
        }
        return reset()
    }

    /**
     * Reset the board to its initial state with only the givens. This method
     * clears any solution, resets statistics, and clears any history messages.
     */
    private func reset() -> Bool {
        solution = Array(repeating: 0, count: QQWing.BOARD_SIZE)
        solutionRound = Array(repeating: 0, count: QQWing.BOARD_SIZE)
        possibilities = Array(repeating: 0, count: QQWing.POSSIBILITY_SIZE)
        solveHistory = []
        solveInstructions = []

        let round: Int = 1
        for position in (0..<QQWing.BOARD_SIZE) {
            if (puzzle[position] > 0) {
                let valIndex: Int = puzzle[position] - 1
                let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                let value: Int = puzzle[position]
                if (possibilities[valPos] != 0) {
                    return false
                }
                try? mark(position, round, value)
                if (logHistory || recordHistory) {
                    addHistoryItem(LogItem(round, LogType.GIVEN, value, position))
                }
            }
        }

        return true
    }

    /**
     * Get the difficulty rating.
     */
    public func getDifficulty() -> Difficulty {
        if (getGuessCount() > 0) { return Difficulty.EXPERT }
        if (getBoxLineReductionCount() > 0) { return Difficulty.INTERMEDIATE }
        if (getPointingPairTripleCount() > 0) { return Difficulty.INTERMEDIATE }
        if (getHiddenPairCount() > 0) { return Difficulty.INTERMEDIATE }
        if (getNakedPairCount() > 0) { return Difficulty.INTERMEDIATE }
        if (getHiddenSingleCount() > 0) { return Difficulty.EASY }
        if (getSingleCount() > 0) { return Difficulty.SIMPLE }
        return Difficulty.UNKNOWN
    }

    /**
     * Get the difficulty rating.
     */
    public func getDifficultyAsString() -> String {
        return getDifficulty().rawValue
    }

    /**
     * Get the number of cells for which the solution was determined because
     * there was only one possible value for that cell.
     */
    public func getSingleCount() -> Int {
        return getLogCount(solveInstructions, LogType.SINGLE)
    }

    /**
     * Get the number of cells for which the solution was determined because
     * that cell had the only possibility for some value in the row, column, or
     * section.
     */
    public func getHiddenSingleCount() -> Int {
        return (
                getLogCount(solveInstructions, LogType.HIDDEN_SINGLE_ROW) +
                getLogCount(solveInstructions, LogType.HIDDEN_SINGLE_COLUMN) +
                getLogCount(solveInstructions, LogType.HIDDEN_SINGLE_SECTION))
    }

    /**
     * Get the number of naked pair reductions that were performed in solving
     * this puzzle.
     */
    public func getNakedPairCount() -> Int {
        return (
                getLogCount(solveInstructions, LogType.NAKED_PAIR_ROW) +
                getLogCount(solveInstructions, LogType.NAKED_PAIR_COLUMN) +
                getLogCount(solveInstructions, LogType.NAKED_PAIR_SECTION))
    }

    /**
     * Get the number of hidden pair reductions that were performed in solving
     * this puzzle.
     */
    public func getHiddenPairCount() -> Int {
        return (
                getLogCount(solveInstructions, LogType.HIDDEN_PAIR_ROW) +
                getLogCount(solveInstructions, LogType.HIDDEN_PAIR_COLUMN) +
                getLogCount(solveInstructions, LogType.HIDDEN_PAIR_SECTION))
    }

    /**
     * Get the number of pointing pair/triple reductions that were performed in
     * solving this puzzle.
     */
    public func getPointingPairTripleCount() -> Int {
        return (
                getLogCount(solveInstructions, LogType.POINTING_PAIR_TRIPLE_ROW) +
                getLogCount(solveInstructions, LogType.POINTING_PAIR_TRIPLE_COLUMN))
    }

    /**
     * Get the number of box/line reductions that were performed in solving this
     * puzzle.
     */
    public func getBoxLineReductionCount() -> Int {
        return (
                getLogCount(solveInstructions, LogType.ROW_BOX) +
                getLogCount(solveInstructions, LogType.COLUMN_BOX))
    }

    /**
     * Get the number lucky guesses in solving this puzzle.
     */
    public func getGuessCount() -> Int {
        return getLogCount(solveInstructions, LogType.GUESS)
    }

    /**
     * Get the number of backtracks (unlucky guesses) required when solving this
     * puzzle.
     */
    public func getBacktrackCount() -> Int {
        return getLogCount(solveHistory, LogType.ROLLBACK)
    }

    private func shuffleRandomArrays() {
        QQWing.shuffleArray(&randomBoardArray, random);
        QQWing.shuffleArray(&randomPossibilityArray, random);
    }

    private func clearPuzzle() {
        // Clear any existing puzzle
        puzzle = Array(repeating: 0, count: QQWing.BOARD_SIZE)
        let _ = reset()
    }

    public func generatePuzzle() -> Bool {
        return generatePuzzleSymmetry(Symmetry.NONE);
    }

    public func generatePuzzleSymmetry(_ sym: Symmetry) -> Bool {
        symmetry = sym
        if (symmetry == Symmetry.RANDOM) {
            symmetry = QQWing.getRandomSymmetry(random)
        }

        // Don't record history while generating.
        let recHistory: Bool = recordHistory
        setRecordHistory(false)
        let lHistory: Bool = logHistory
        setLogHistory(false)

        clearPuzzle()

        // Start by getting the randomness in order so that
        // each puzzle will be different from the last.
        shuffleRandomArrays()

        // Now solve the puzzle the whole way. The solve
        // uses random algorithms, so we should have a
        // really randomly totally filled sudoku
        // Even when starting from an empty grid
        let _ = solve()

        if (symmetry == Symmetry.NONE) {
            // Rollback any square for which it is obvious that
            // the square doesn't contribute to a unique solution
            // (ie, squares that were filled by logic rather
            // than by guess)
            rollbackNonGuesses()
        }

        // Record all marked squares as the puzzle so
        // that we can call countSolutions without losing it.
        puzzle = solution

        // Rerandomize everything so that we test squares
        // in a different order than they were added.
        shuffleRandomArrays()

        // Remove one value at a time and see if
        // the puzzle still has only one solution.
        // If it does, leave it out the point because
        // it is not needed.
        for i in (0..<QQWing.BOARD_SIZE) {
            // check all the positions, but in shuffled order
            let position: Int = randomBoardArray[i]
            if (puzzle[position] > 0) {
                var positionsym1: Int = -1
                var positionsym2: Int = -1
                var positionsym3: Int = -1
                switch (symmetry) {
                case .ROTATE90:
                    positionsym2 = QQWing.rowColumnToCell(QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToColumn(position), QQWing.cellToRow(position))
                    positionsym3 = QQWing.rowColumnToCell(QQWing.cellToColumn(position), QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToRow(position))
                    fallthrough
                case .ROTATE180:
                    positionsym1 = QQWing.rowColumnToCell(QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToRow(position), QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToColumn(position))
                case .MIRROR:
                    positionsym1 = QQWing.rowColumnToCell(QQWing.cellToRow(position), QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToColumn(position))
                case .FLIP:
                    positionsym1 = QQWing.rowColumnToCell(QQWing.ROW_COL_SEC_SIZE - 1 - QQWing.cellToRow(position), QQWing.cellToColumn(position))
                default:
                    break;
                }
                // try backing out the value and
                // counting solutions to the puzzle
                let savedValue: Int = puzzle[position]
                puzzle[position] = 0
                var savedSym1: Int = 0
                if (positionsym1 >= 0) {
                    savedSym1 = puzzle[positionsym1]
                    puzzle[positionsym1] = 0
                }
                var savedSym2: Int = 0
                if (positionsym2 >= 0) {
                    savedSym2 = puzzle[positionsym2]
                    puzzle[positionsym2] = 0
                }
                var savedSym3: Int = 0
                if (positionsym3 >= 0) {
                    savedSym3 = puzzle[positionsym3]
                    puzzle[positionsym3] = 0
                }
                let _ = reset();
                if (countSolutions(2, true) > 1) {
                    // Put it back in, it is needed
                    puzzle[position] = savedValue
                    if (positionsym1 >= 0 && savedSym1 != 0) { puzzle[positionsym1] = savedSym1 }
                    if (positionsym2 >= 0 && savedSym2 != 0) { puzzle[positionsym2] = savedSym2 }
                    if (positionsym3 >= 0 && savedSym3 != 0) { puzzle[positionsym3] = savedSym3 }
                }
            }
        }

        // Clear all solution info, leaving just the puzzle.
        let _ = reset()

        // Restore recording history.
        setRecordHistory(recHistory)
        setLogHistory(lHistory)

        return true
    }

    private func rollbackNonGuesses() {
        // Guesses are odd rounds
        // Non-guesses are even rounds
        for i in stride(from: 2, through: lastSolveRound, by: 2) {
            rollbackRound(i);
        }
    }

    public func setPrintStyle(_ ps: PrintStyle) {
        printStyle = ps
    }

    public func setRecordHistory(_ recHistory: Bool) {
        recordHistory = recHistory
    }

    public func setLogHistory(_ logHist: Bool) {
        logHistory = logHist
    }

    private func addHistoryItem(_ l: LogItem) {
        if (logHistory) {
            print(l.description)
            print()
        }
        if (recordHistory) {
            solveHistory.append(l)
            solveInstructions.append(l)
        }
    }

    private func printHistory(_ v: [LogItem]) {
        print(historyToString(v))
    }

    private func historyToString(_ v: [LogItem]) -> String {
        var sb: String = ""
        if (!recordHistory) {
            sb.append("History was not recorded.")
            sb.append(QQWing.NL)
            if (printStyle == PrintStyle.CSV) {
                sb.append(" -- ")
                sb.append(QQWing.NL)
            } else {
                sb.append(QQWing.NL)
            }
        }
        for i in (0..<v.count) {
            sb.append(String(i + 1) + ". ")
            sb.append(QQWing.NL)
            print(v[i].description)
            if (printStyle == PrintStyle.CSV) {
                sb.append(" -- ")
                sb.append(QQWing.NL)
            } else {
                sb.append(QQWing.NL)
            }
        }
        if (printStyle == PrintStyle.CSV) {
            sb.append(",")
            sb.append(QQWing.NL)
        } else {
            sb.append(QQWing.NL)
        }
        return sb
    }

    public func printSolveInstructions() {
        print(getSolveInstructionsString())
    }

    public func getSolveInstructionsString() -> String {
        if (isSolved()) {
            return historyToString(solveInstructions)
        } else {
            return "No solve instructions - Puzzle is not possible to solve."
        }
    }

    public func getSolveInstructions() -> [LogItem] {
        if (isSolved()) {
            return Array(solveInstructions)
        } else {
            return []
        }
    }

    public func printSolveHistory() {
        printHistory(solveHistory)
    }

    public func getSolveHistoryString() -> String {
        return historyToString(solveHistory)
    }

    public func getSolveHistory() -> [LogItem] {
        return Array(solveHistory)
    }

    public func solve() -> Bool {
        let _ = reset()
        shuffleRandomArrays()
        return solve(2)
    }

    private func solve(_ round: Int) -> Bool {
        lastSolveRound = round

        while (singleSolveMove(round)) {
            if (isSolved()) { return true }
            if (isImpossible()) { return false }
        }

        let nextGuessRound: Int = round + 1
        let nextRound: Int = round + 2
        var guessNumber = 0
        while(guess(nextGuessRound, guessNumber)){
            if (isImpossible() || !solve(nextRound)) {
                rollbackRound(nextRound)
                rollbackRound(nextGuessRound)
            } else {
                return true
            }
            guessNumber += 1
        }
        return false
    }

    /**
     * return true if the puzzle has no solutions at all
     */
    public func hasNoSolution() -> Bool {
        return countSolutionsLimited() == 0
    }

    /**
     * return true if the puzzle has a solution
     * and only a single solution
     */
    public func hasUniqueSolution() -> Bool {
        return countSolutionsLimited() == 1
    }

    /**
     * return true if the puzzle has more than one solution
     */
    public func hasMultipleSolutions() -> Bool {
        return countSolutionsLimited() > 1
    }

    /**
     * Count the number of solutions to the puzzle
     */
    public func countSolutions() -> Int {
        return countSolutions(false)
    }

    /**
     * Count the number of solutions to the puzzle
     * but return two any time there are two or
     * more solutions.  This method will run much
     * faster than countSolutions() when there
     * are many possible solutions and can be used
     * when you are interested in knowing if the
     * puzzle has zero, one, or multiple solutions.
     */
    public func countSolutionsLimited() -> Int {
        return countSolutions(true)
    }

    private func countSolutions(_ limitToTwo: Bool) -> Int {
        // Don't record history while generating.
        let recHistory: Bool = recordHistory
        setRecordHistory(false)
        let lHistory: Bool = logHistory
        setLogHistory(false)

        let _ = reset()
        let solutionCount: Int = countSolutions(2, limitToTwo)

        // Restore recording history.
        setRecordHistory(recHistory)
        setLogHistory(lHistory)

        return solutionCount
    }

    private func countSolutions(_ round: Int, _ limitToTwo: Bool) -> Int {
        while (singleSolveMove(round)) {
            if (isSolved()) {
                rollbackRound(round)
                return 1
            }
            if (isImpossible()) {
                rollbackRound(round)
                return 0
            }
        }

        var solutions: Int = 0
        let nextRound: Int = round + 1
        var guessNumber = 0
        while(guess(nextRound, guessNumber)){
            solutions += countSolutions(nextRound, limitToTwo)
            if (limitToTwo && solutions >= 2) {
                rollbackRound(round)
                return solutions
            }
            guessNumber += 1
        }
        rollbackRound(round)
        return solutions
    }

    private func rollbackRound(_ round: Int) {
        if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.ROLLBACK)) }
        for i in (0..<QQWing.BOARD_SIZE) {
            if (solutionRound[i] == round) {
                solutionRound[i] = 0
                solution[i] = 0
            }
        }
        for i in (0..<QQWing.POSSIBILITY_SIZE) {
            if (possibilities[i] == round) {
                possibilities[i] = 0
            }
        }
        while (solveInstructions.count > 0 && solveInstructions.last!.round == round) {
            let _ = solveInstructions.popLast()
        }
    }

    public func isSolved() -> Bool {
        return !solution.contains(0)
    }

    private func isImpossible() -> Bool {
        for position in (0..<QQWing.BOARD_SIZE) {
            if (solution[position] == 0) {
                var count: Int = 0
                for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) { count += 1 }
                }
                if (count == 0) {
                    return true
                }
            }
        }
        return false;
    }

    private func findPositionWithFewestPossibilities() -> Int {
        var minPossibilities: Int = 10
        var bestPosition: Int = 0
        for i in (0..<QQWing.BOARD_SIZE) {
            let position: Int = randomBoardArray[i]
            if (solution[position] == 0) {
                var count: Int = 0
                for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) { count += 1 }
                }
                if (count < minPossibilities) {
                    minPossibilities = count
                    bestPosition = position
                }
            }
        }
        return bestPosition
    }

    private func guess(_ round: Int, _ guessNumber: Int) -> Bool {
        var localGuessCount: Int = 0
        let position: Int = findPositionWithFewestPossibilities()
        for i in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let valIndex: Int = randomPossibilityArray[i]
            let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
            if (possibilities[valPos] == 0) {
                if (localGuessCount == guessNumber) {
                    let value: Int = valIndex + 1
                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.GUESS, value, position)) }
                    try? mark(position, round, value)
                    return true
                }
                localGuessCount += 1
            }
        }
        return false
    }

    private func singleSolveMove(_ round: Int) -> Bool {
        if (onlyPossibilityForCell(round)) { return true }
        if (onlyValueInSection(round)) { return true}
        if (onlyValueInRow(round)) { return true }
        if (onlyValueInColumn(round)) { return true }
        if (handleNakedPairs(round)) { return true }
        if (pointingRowReduction(round)) { return true }
        if (pointingColumnReduction(round)) { return true }
        if (rowBoxReduction(round)) { return true }
        if (colBoxReduction(round)) { return true }
        if (hiddenPairInRow(round)) { return true }
        if (hiddenPairInColumn(round)) { return true }
        if (hiddenPairInSection(round)) { return true }
        return false
    }

    private func colBoxReduction(_ round: Int) -> Bool {
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for col in (0..<QQWing.ROW_COL_SEC_SIZE) {
                let colStart: Int = QQWing.columnToFirstCell(col)
                var inOneBox: Bool = true
                var colBox: Int = -1
                for i in (0..<QQWing.GRID_SIZE) {
                    for j in (0..<QQWing.GRID_SIZE) {
                        let row: Int = i * QQWing.GRID_SIZE + j
                        let position: Int = QQWing.rowColumnToCell(row, col)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                        if (possibilities[valPos] == 0) {
                            if (colBox == -1 || colBox == i) {
                                colBox = i
                            } else {
                                inOneBox = false
                            }
                        }
                    }
                }
                if (inOneBox && colBox != -1) {
                    var doneSomething: Bool = false
                    let row: Int = QQWing.GRID_SIZE * colBox
                    let secStart: Int = QQWing.cellToSectionStartCell(QQWing.rowColumnToCell(row, col))
                    let secStartRow: Int = QQWing.cellToRow(secStart)
                    let secStartCol: Int = QQWing.cellToColumn(secStart)
                    for i in (0..<QQWing.GRID_SIZE) {
                        for j in (0..<QQWing.GRID_SIZE) {
                            let row2: Int = secStartRow + i
                            let col2: Int = secStartCol + j
                            let position: Int = QQWing.rowColumnToCell(row2, col2)
                            let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                            if (col != col2 && possibilities[valPos] == 0) {
                                possibilities[valPos] = round
                                doneSomething = true
                            }
                        }
                    }
                    if (doneSomething) {
                        if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.COLUMN_BOX, valIndex + 1, colStart)) }
                        return true
                    }
                }
            }
        }
        return false
    }

    private func rowBoxReduction(_ round: Int) -> Bool {
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
                let rowStart: Int = QQWing.rowToFirstCell(row)
                var inOneBox: Bool = true
                var rowBox: Int = -1
                for i in (0..<QQWing.GRID_SIZE) {
                    for j in (0..<QQWing.GRID_SIZE) {
                        let column: Int = i * QQWing.GRID_SIZE + j
                        let position: Int = QQWing.rowColumnToCell(row, column)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                        if (possibilities[valPos] == 0) {
                            if (rowBox == -1 || rowBox == i) {
                                rowBox = i
                            } else {
                                inOneBox = false
                            }
                        }
                    }
                }
                if (inOneBox && rowBox != -1) {
                    var doneSomething: Bool = false
                    let column = QQWing.GRID_SIZE * rowBox
                    let secStart: Int = QQWing.cellToSectionStartCell(QQWing.rowColumnToCell(row, column))
                    let secStartRow: Int = QQWing.cellToRow(secStart)
                    let secStartCol: Int = QQWing.cellToColumn(secStart)
                    for i in (0..<QQWing.GRID_SIZE) {
                        for j in (0..<QQWing.GRID_SIZE) {
                            let row2: Int = secStartRow + i
                            let col2: Int = secStartCol + j
                            let position: Int = QQWing.rowColumnToCell(row2, col2)
                            let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                            if (row != row2 && possibilities[valPos] == 0) {
                                possibilities[valPos] = round
                                doneSomething = true
                            }
                        }
                    }
                    if (doneSomething) {
                        if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.ROW_BOX, valIndex + 1, rowStart)) }
                        return true
                    }
                }
            }
        }
        return false
    }

    private func pointingRowReduction(_ round: Int) -> Bool {
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for section in (0..<QQWing.ROW_COL_SEC_SIZE) {
                let secStart: Int = QQWing.sectionToFirstCell(section)
                var inOneRow: Bool = true
                var boxRow: Int = -1
                for j in (0..<QQWing.GRID_SIZE) {
                    for i in (0..<QQWing.GRID_SIZE) {
                        let secVal: Int = secStart + i + (QQWing.ROW_COL_SEC_SIZE * j)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, secVal)
                        if (possibilities[valPos] == 0) {
                            if (boxRow == -1 || boxRow == j) {
                                boxRow = j
                            } else {
                                inOneRow = false
                            }
                        }
                    }
                }
                if (inOneRow && boxRow != -1) {
                    var doneSomething: Bool = false
                    let row: Int = QQWing.cellToRow(secStart) + boxRow
                    let rowStart: Int = QQWing.rowToFirstCell(row)

                    for i in (0..<QQWing.ROW_COL_SEC_SIZE) {
                        let position: Int = rowStart + i
                        let section2: Int = QQWing.cellToSection(position)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                        if (section != section2 && possibilities[valPos] == 0) {
                            possibilities[valPos] = round
                            doneSomething = true
                        }
                    }
                    if (doneSomething) {
                        if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.POINTING_PAIR_TRIPLE_ROW, valIndex + 1, rowStart)) }
                        return true
                    }
                }
            }
        }
        return false
    }

    private func pointingColumnReduction(_ round: Int) -> Bool {
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for section in (0..<QQWing.ROW_COL_SEC_SIZE) {
                let secStart: Int = QQWing.sectionToFirstCell(section)
                var inOneCol: Bool = true
                var boxCol: Int = -1
                for i in (0..<QQWing.GRID_SIZE) {
                    for j in (0..<QQWing.GRID_SIZE) {
                        let secVal: Int = secStart + i + (QQWing.ROW_COL_SEC_SIZE * j)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, secVal)
                        if (possibilities[valPos] == 0) {
                            if (boxCol == -1 || boxCol == i) {
                                boxCol = i
                            } else {
                                inOneCol = false
                            }
                        }
                    }
                }
                if (inOneCol && boxCol != -1) {
                    var doneSomething: Bool = false
                    let col: Int = QQWing.cellToColumn(secStart) + boxCol
                    let colStart: Int = QQWing.columnToFirstCell(col)

                    for i in (0..<QQWing.ROW_COL_SEC_SIZE) {
                        let position: Int = colStart + (QQWing.ROW_COL_SEC_SIZE * i)
                        let section2: Int = QQWing.cellToSection(position)
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                        if (section != section2 && possibilities[valPos] == 0) {
                            possibilities[valPos] = round
                            doneSomething = true
                        }
                    }
                    if (doneSomething) {
                        if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.POINTING_PAIR_TRIPLE_COLUMN, valIndex + 1, colStart)) }
                        return true
                    }
                }
            }
        }
        return false
    }

    private func countPossibilities(_ position: Int) -> Int {
        var count: Int = 0
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
            if (possibilities[valPos] == 0) { count += 1 }
        }
        return count
    }

    private func arePossibilitiesSame(_ position1: Int, _ position2: Int) -> Bool {
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let valPos1: Int = QQWing.getPossibilityIndex(valIndex, position1)
            let valPos2: Int = QQWing.getPossibilityIndex(valIndex, position2)
            if ((possibilities[valPos1] == 0 || possibilities[valPos2] == 0) && (possibilities[valPos1] != 0 || possibilities[valPos2] != 0)) {
                return false
            }
        }
        return true
    }

    private func removePossibilitiesInOneFromTwo(_ position1: Int, _ position2: Int, _ round: Int) -> Bool {
        var doneSomething: Bool = false
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let valPos1: Int = QQWing.getPossibilityIndex(valIndex, position1)
            let valPos2: Int = QQWing.getPossibilityIndex(valIndex, position2)
            if (possibilities[valPos1] == 0 && possibilities[valPos2] == 0) {
                possibilities[valPos2] = round
                doneSomething = true
            }
        }
        return doneSomething
    }

    private func hiddenPairInColumn(_ round: Int) -> Bool {
        for column in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var r1: Int = -1
                var r2: Int = -1
                var valCount: Int = 0
                for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let position: Int = QQWing.rowColumnToCell(row, column)
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        if (r1 == -1 || r1 == row) {
                            r1 = row
                        } else if (r2 == -1 || r2 == row) {
                            r2 = row
                        }
                        valCount += 1
                    }
                }
                if (valCount == 2) {
                    for valIndex2 in ((valIndex + 1)..<QQWing.ROW_COL_SEC_SIZE) {
                        var r3: Int = -1
                        var r4: Int = -1
                        var valCount2: Int = 0
                        for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
                            let position: Int = QQWing.rowColumnToCell(row, column)
                            let valPos: Int = QQWing.getPossibilityIndex(valIndex2, position)
                            if (possibilities[valPos] == 0) {
                                if (r3 == -1 || r3 == row) {
                                    r3 = row
                                } else if (r4 == -1 || r4 == row) {
                                    r4 = row
                                }
                                valCount2 += 1
                            }
                        }
                        if (valCount2 == 2 && r1 == r3 && r2 == r4) {
                            var doneSomething: Bool = false
                            for valIndex3 in (0..<QQWing.ROW_COL_SEC_SIZE) {
                                if (valIndex3 != valIndex && valIndex3 != valIndex2) {
                                    let position1: Int = QQWing.rowColumnToCell(r1, column)
                                    let position2: Int = QQWing.rowColumnToCell(r2, column)
                                    let valPos1: Int = QQWing.getPossibilityIndex(valIndex3, position1)
                                    let valPos2: Int = QQWing.getPossibilityIndex(valIndex3, position2)
                                    if (possibilities[valPos1] == 0) {
                                        possibilities[valPos1] = round
                                        doneSomething = true
                                    }
                                    if (possibilities[valPos2] == 0) {
                                        possibilities[valPos2] = round
                                        doneSomething = true
                                    }
                                }
                            }
                            if (doneSomething) {
                                if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_PAIR_COLUMN, valIndex + 1, QQWing.rowColumnToCell(r1, column))) }
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    private func hiddenPairInSection(_ round: Int) -> Bool {
        for section in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var si1: Int = -1
                var si2: Int = -1
                var valCount: Int = 0
                for secInd in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let position: Int = QQWing.sectionToCell(section, secInd)
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        if (si1 == -1 || si1 == secInd) {
                            si1 = secInd
                        } else if (si2 == -1 || si2 == secInd) {
                            si2 = secInd
                        }
                        valCount += 1
                    }
                }
                if (valCount == 2) {
                    for valIndex2 in ((valIndex + 1)..<QQWing.ROW_COL_SEC_SIZE) {
                        var si3: Int = -1
                        var si4: Int = -1
                        var valCount2: Int = 0
                        for secInd in (0..<QQWing.ROW_COL_SEC_SIZE) {
                            let position: Int = QQWing.sectionToCell(section, secInd)
                            let valPos: Int = QQWing.getPossibilityIndex(valIndex2, position)
                            if (possibilities[valPos] == 0) {
                                if (si3 == -1 || si3 == secInd) {
                                    si3 = secInd
                                } else if (si4 == -1 || si4 == secInd) {
                                    si4 = secInd
                                }
                                valCount2 += 1
                            }
                        }
                        if (valCount2 == 2 && si1 == si3 && si2 == si4) {
                            var doneSomething: Bool = false
                            for valIndex3 in (0..<QQWing.ROW_COL_SEC_SIZE) {
                                if (valIndex3 != valIndex && valIndex3 != valIndex2) {
                                    let position1: Int = QQWing.sectionToCell(section, si1)
                                    let position2: Int = QQWing.sectionToCell(section, si2)
                                    let valPos1: Int = QQWing.getPossibilityIndex(valIndex3, position1)
                                    let valPos2: Int = QQWing.getPossibilityIndex(valIndex3, position2)
                                    if (possibilities[valPos1] == 0) {
                                        possibilities[valPos1] = round
                                        doneSomething = true
                                    }
                                    if (possibilities[valPos2] == 0) {
                                        possibilities[valPos2] = round
                                        doneSomething = true
                                    }
                                }
                            }
                            if (doneSomething) {
                                if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_PAIR_SECTION, valIndex + 1, QQWing.sectionToCell(section, si1))) }
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    private func hiddenPairInRow(_ round: Int) -> Bool {
        for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var c1: Int = -1
                var c2: Int = -1
                var valCount: Int = 0
                for column in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let position: Int = QQWing.rowColumnToCell(row, column)
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        if (c1 == -1 || c1 == column) {
                            c1 = column
                        } else if (c2 == -1 || c2 == column) {
                            c2 = column
                        }
                        valCount += 1
                    }
                }
                if (valCount == 2) {
                    for valIndex2 in ((valIndex + 1)..<QQWing.ROW_COL_SEC_SIZE) {
                        var c3: Int = -1
                        var c4: Int = -1
                        var valCount2: Int = 0
                        for column in (0..<QQWing.ROW_COL_SEC_SIZE) {
                            let position: Int = QQWing.rowColumnToCell(row, column)
                            let valPos: Int = QQWing.getPossibilityIndex(valIndex2, position)
                            if (possibilities[valPos] == 0) {
                                if (c3 == -1 || c3 == column) {
                                    c3 = column
                                } else if (c4 == -1 || c4 == column) {
                                    c4 = column
                                }
                                valCount2 += 1
                            }
                        }
                        if (valCount2 == 2 && c1 == c3 && c2 == c4) {
                            var doneSomething: Bool = false
                            for valIndex3 in (0..<QQWing.ROW_COL_SEC_SIZE) {
                                if (valIndex3 != valIndex && valIndex3 != valIndex2) {
                                    let position1: Int = QQWing.rowColumnToCell(row, c1)
                                    let position2: Int = QQWing.rowColumnToCell(row, c2)
                                    let valPos1: Int = QQWing.getPossibilityIndex(valIndex3, position1)
                                    let valPos2: Int = QQWing.getPossibilityIndex(valIndex3, position2)
                                    if (possibilities[valPos1] == 0) {
                                        possibilities[valPos1] = round
                                        doneSomething = true
                                    }
                                    if (possibilities[valPos2] == 0) {
                                        possibilities[valPos2] = round
                                        doneSomething = true
                                    }
                                }
                            }
                            if (doneSomething) {
                                if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_PAIR_ROW, valIndex + 1, QQWing.rowColumnToCell(row, c1))) }
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    private func handleNakedPairs(_ round: Int) -> Bool {
        for position in (0..<QQWing.BOARD_SIZE) {
            let possibilities: Int = countPossibilities(position)
            if (possibilities == 2) {
                let row: Int = QQWing.cellToRow(position)
                let column: Int = QQWing.cellToColumn(position)
                let section: Int = QQWing.cellToSectionStartCell(position)
                for position2 in (position..<QQWing.BOARD_SIZE) {
                    if (position != position2) {
                        let possibilities2: Int = countPossibilities(position2)
                        if (possibilities2 == 2 && arePossibilitiesSame(position, position2)) {
                            if (row == QQWing.cellToRow(position2)) {
                                var doneSomething: Bool = false
                                for column2 in (0..<QQWing.ROW_COL_SEC_SIZE) {
                                    let position3: Int = QQWing.rowColumnToCell(row, column2)
                                    if (position3 != position && position3 != position2 && removePossibilitiesInOneFromTwo(position, position3, round)) {
                                        doneSomething = true
                                    }
                                }
                                if (doneSomething) {
                                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.NAKED_PAIR_ROW, 0, position)) }
                                    return true
                                }
                            }
                            if (column == QQWing.cellToColumn(position2)) {
                                var doneSomething: Bool = false
                                for row2 in (0..<QQWing.ROW_COL_SEC_SIZE) {
                                    let position3: Int = QQWing.rowColumnToCell(row2, column)
                                    if (position3 != position && position3 != position2 && removePossibilitiesInOneFromTwo(position, position3, round)) {
                                        doneSomething = true
                                    }
                                }
                                if (doneSomething) {
                                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.NAKED_PAIR_COLUMN, 0, position)) }
                                    return true
                                }
                            }
                            if (section == QQWing.cellToSectionStartCell(position2)) {
                                var doneSomething: Bool = false
                                let secStart: Int = QQWing.cellToSectionStartCell(position)
                                for i in (0..<3) {
                                    for j in (0..<3) {
                                        let position3: Int = secStart + i + (QQWing.ROW_COL_SEC_SIZE * j)
                                        if (position3 != position && position3 != position2 && removePossibilitiesInOneFromTwo(position, position3, round)) {
                                            doneSomething = true
                                        }
                                    }
                                }
                                if (doneSomething) {
                                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.NAKED_PAIR_SECTION, 0, position)) }
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    /**
     * Mark exactly one cell which is the only possible value for some row, if
     * such a cell exists. This method will look in a row for a possibility that
     * is only listed for one cell. This type of cell is often called a
     * "hidden single"
     */
    private func onlyValueInRow(_ round: Int) -> Bool {
        for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var count: Int = 0
                var lastPosition: Int = 0
                for col in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let position: Int = (row * QQWing.ROW_COL_SEC_SIZE) + col
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        count += 1
                        lastPosition = position
                    }
                }
                if (count == 1) {
                    let value: Int = valIndex + 1
                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_SINGLE_ROW, value, lastPosition)) }
                    try? mark(lastPosition, round, value)
                    return true
                }
            }
        }
        return false
    }

    /**
     * Mark exactly one cell which is the only possible value for some column,
     * if such a cell exists. This method will look in a column for a
     * possibility that is only listed for one cell. This type of cell is often
     * called a "hidden single"
     */
    private func onlyValueInColumn(_ round: Int) -> Bool {
        for col in (0..<QQWing.ROW_COL_SEC_SIZE) {
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var count: Int = 0
                var lastPosition: Int = 0
                for row in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let position: Int = QQWing.rowColumnToCell(row, col)
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        count += 1
                        lastPosition = position
                    }
                }
                if (count == 1) {
                    let value = valIndex + 1
                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_SINGLE_COLUMN, value, lastPosition)) }
                    try? mark(lastPosition, round, value)
                    return true
                }
            }
        }
        return false
    }

    /**
     * Mark exactly one cell which is the only possible value for some section,
     * if such a cell exists. This method will look in a section for a
     * possibility that is only listed for one cell. This type of cell is often
     * called a "hidden single"
     */
    private func onlyValueInSection(_ round: Int) -> Bool {
        for sec in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let secPos = QQWing.sectionToFirstCell(sec)
            for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                var count: Int = 0
                var lastPosition: Int = 0
                for i in (0..<QQWing.GRID_SIZE) {
                    for j in (0..<QQWing.GRID_SIZE) {
                        let position: Int = secPos + i + QQWing.ROW_COL_SEC_SIZE * j
                        let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                        if (possibilities[valPos] == 0) {
                            count += 1
                            lastPosition = position
                        }
                    }
                }
                if (count == 1) {
                    let value: Int = valIndex + 1
                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.HIDDEN_SINGLE_SECTION, value, lastPosition)) }
                    try? mark(lastPosition, round, value)
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Mark exactly one cell that has a single possibility, if such a cell
     * exists. This method will look for a cell that has only one possibility.
     * This type of cell is often called a "single"
     */
    private func onlyPossibilityForCell(_ round: Int) -> Bool {
        for position in (0..<QQWing.BOARD_SIZE) {
            if (solution[position] == 0) {
                var count: Int = 0
                var lastValue: Int = 0
                for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
                    let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
                    if (possibilities[valPos] == 0) {
                        count += 1
                        lastValue = valIndex + 1
                    }
                }
                if (count == 1) {
                    try? mark(position, round, lastValue)
                    if (logHistory || recordHistory) { addHistoryItem(LogItem(round, LogType.SINGLE, lastValue, position)) }
                    return true
                }
            }
        }
        return false;
    }

    /**
     * Mark the given value at the given position. Go through the row, column,
     * and section for the position and remove the value from the possibilities.
     *
     * @param position Position into the board (0-80)
     * @param round Round to mark for rollback purposes
     * @param value The value to go in the square at the given position
     */
    private func mark(_ position: Int, _ round: Int, _ value: Int) throws {
        if (solution[position] != 0) { throw Errors.IllegalArgumentException(message: "Marking position that already has been marked.") }
        if (solutionRound[position] != 0) { throw Errors.IllegalArgumentException(message: "Marking position that was marked another round.") }
        let valIndex: Int = value - 1
        solution[position] = value

        let possInd: Int = QQWing.getPossibilityIndex(valIndex, position)
        if (possibilities[possInd] != 0) { throw Errors.IllegalArgumentException(message: "Marking impossible position.") }

        // Take this value out of the possibilities for everything in the row
        solutionRound[position] = round
        let rowStart: Int = QQWing.cellToRow(position) * QQWing.ROW_COL_SEC_SIZE
        for col in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let rowVal: Int = rowStart + col
            let valPos: Int = QQWing.getPossibilityIndex(valIndex, rowVal)
            // System.out.println("Row Start: "+rowStart+" Row Value: "+rowVal+" Value Position: "+valPos);
            if (possibilities[valPos] == 0) {
                possibilities[valPos] = round
            }
        }

        // Take this value out of the possibilities for everything in the column
        let colStart: Int = QQWing.cellToColumn(position);
        for i in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let colVal: Int = colStart + (QQWing.ROW_COL_SEC_SIZE * i)
            let valPos: Int = QQWing.getPossibilityIndex(valIndex, colVal)
            // System.out.println("Col Start: "+colStart+" Col Value: "+colVal+" Value Position: "+valPos);
            if (possibilities[valPos] == 0) {
                possibilities[valPos] = round
            }
        }

        // Take this value out of the possibilities for everything in section
        let secStart: Int = QQWing.cellToSectionStartCell(position)
        for i in (0..<QQWing.GRID_SIZE) {
            for j in (0..<QQWing.GRID_SIZE) {
                let secVal = secStart + i + (QQWing.ROW_COL_SEC_SIZE * j)
                let valPos = QQWing.getPossibilityIndex(valIndex, secVal)
                // System.out.println("Sec Start: "+secStart+" Sec Value: "+secVal+" Value Position: "+valPos);
                if (possibilities[valPos] == 0) {
                    possibilities[valPos] = round
                }
            }
        }

        // This position itself is determined, it should have possibilities.
        for valIndex in (0..<QQWing.ROW_COL_SEC_SIZE) {
            let valPos: Int = QQWing.getPossibilityIndex(valIndex, position)
            if (possibilities[valPos] == 0) {
                possibilities[valPos] = round
            }
        }
    }

    /**
     * print the given BOARD_SIZEd array of ints as a sudoku puzzle. Use print
     * options from member variables.
     */
    private func printSudoku(_ sudoku: [Int]) {
        print(puzzleToString(sudoku))
    }

    private func puzzleToString(_ sudoku: [Int]) -> String {
        var sb: String = ""
        for i in (0..<QQWing.BOARD_SIZE) {
            if (printStyle == PrintStyle.READABLE) {
                sb.append(" ")
            }
            if (sudoku[i] == 0) {
                sb.append(".")
            } else {
                sb.append(String(sudoku[i]))
            }
            if (i == QQWing.BOARD_SIZE - 1) {
                if (printStyle == PrintStyle.CSV) {
                    sb.append(",")
                } else {
                    sb.append(QQWing.NL)
                }
                if (printStyle == PrintStyle.READABLE || printStyle == PrintStyle.COMPACT) {
                    sb.append(QQWing.NL)
                }
            } else if (i % QQWing.ROW_COL_SEC_SIZE == QQWing.ROW_COL_SEC_SIZE - 1) {
                if (printStyle == PrintStyle.READABLE || printStyle == PrintStyle.COMPACT) {
                    sb.append(QQWing.NL)
                }
                if (i % QQWing.SEC_GROUP_SIZE == QQWing.SEC_GROUP_SIZE - 1) {
                    if (printStyle == PrintStyle.READABLE) {
                        sb.append("-------|-------|-------")
                        sb.append(QQWing.NL)
                    }
                }
            } else if (i % QQWing.GRID_SIZE == QQWing.GRID_SIZE - 1) {
                if (printStyle == PrintStyle.READABLE) {
                    sb.append(" |")
                }
            }
        }
        return sb
    }

    /**
     * Print the sudoku puzzle.
     */
    public func printPuzzle() {
        printSudoku(puzzle)
    }

    public func getPuzzleString() -> String {
        return puzzleToString(puzzle)
    }

    public func getPuzzle() -> [Int] {
        return Array(puzzle)
    }

    /**
     * Print the sudoku solution.
     */
    public func printSolution() {
        printSudoku(solution)
    }

    public func getSolutionString() -> String {
        return puzzleToString(solution)
    }

    public func getSolution() -> [Int] {
        return Array(solution)
    }

    /**
     * Given a vector of LogItems, determine how many log items in the vector
     * are of the specified type.
     */
    private func getLogCount(_ v: [LogItem], _ type: LogType) -> Int {
        return v.filter { (e:LogItem) in e.type == type}.count
    }

    /**
     * Shuffle the values in an array of integers.
     */
    private static func shuffleArray(_ array: inout [Int], _ random: GKRandomDistribution) {
        for i in (0..<array.count) {
            let tailSize: Int = array.count - i
            let randTailPos: Int = random.nextInt(upperBound: tailSize) + i
            let temp: Int = array[i];
            array[i] = array[randTailPos];
            array[randTailPos] = temp;
        }
    }

    private static func getRandomSymmetry(_ random: GKRandomDistribution) -> Symmetry {
        // not the first and last value which are NONE and RANDOM
        var values: [Symmetry] = [.FLIP, .MIRROR, .ROTATE90, .ROTATE180]
        return values[random.nextInt(upperBound: values.count)]
    }

    /**
     * Given the index of a cell (0-80) calculate the column (0-8) in which that
     * cell resides.
     */
    static func cellToColumn(_ cell: Int) -> Int {
        return cell % ROW_COL_SEC_SIZE
    }

    /**
     * Given the index of a cell (0-80) calculate the row (0-8) in which it
     * resides.
     */
    static func cellToRow(_ cell: Int) -> Int {
        return cell / ROW_COL_SEC_SIZE
    }

    /**
     * Given the index of a cell (0-80) calculate the section (0-8) in which it
     * resides.
     */
    static func cellToSection(_ cell: Int) -> Int {
        return ((cell / SEC_GROUP_SIZE * GRID_SIZE)
                + (cellToColumn(cell) / GRID_SIZE))
    }

    /**
     * Given the index of a cell (0-80) calculate the cell (0-80) that is the
     * upper left start cell of that section.
     */
    static func cellToSectionStartCell(_ cell: Int) -> Int {
        return ((cell / SEC_GROUP_SIZE * SEC_GROUP_SIZE)
                + (cellToColumn(cell) / GRID_SIZE * GRID_SIZE))
    }

    /**
     * Given a row (0-8) calculate the first cell (0-80) of that row.
     */
    static func rowToFirstCell(_ row: Int) -> Int {
        return 9 * row
    }

    /**
     * Given a column (0-8) calculate the first cell (0-80) of that column.
     */
    static func columnToFirstCell(_ column: Int) -> Int {
        return column
    }

    /**
     * Given a section (0-8) calculate the first cell (0-80) of that section.
     */
    static func sectionToFirstCell(_ section: Int) -> Int {
        return ((section % GRID_SIZE * GRID_SIZE)
                + (section / GRID_SIZE * SEC_GROUP_SIZE))
    }

    /**
     * Given a value for a cell (0-8) and a cell number (0-80) calculate the
     * offset into the possibility array (0-728).
     */
    static func getPossibilityIndex(_ valueIndex: Int, _ cell: Int) -> Int {
        return valueIndex + (ROW_COL_SEC_SIZE * cell)
    }

    /**
     * Given a row (0-8) and a column (0-8) calculate the cell (0-80).
     */
    static func rowColumnToCell(_ row: Int, _ column: Int) -> Int {
        return (row * ROW_COL_SEC_SIZE) + column
    }

    /**
     * Given a section (0-8) and an offset into that section (0-8) calculate the
     * cell (0-80)
     */
    static func sectionToCell(_ section: Int, _ offset: Int) -> Int {
        return (sectionToFirstCell(section)
                + ((offset / GRID_SIZE) * ROW_COL_SEC_SIZE)
                + (offset % GRID_SIZE))
    }
}

enum Errors: Error {
    case IllegalArgumentException(message: String)
}