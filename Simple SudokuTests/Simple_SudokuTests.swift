//
//  Simple_SudokuTests.swift
//  Simple SudokuTests
//
//  Created by Jonas Theslöf on 2018-08-23.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import XCTest
@testable import Simple_Sudoku

class Simple_SudokuTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        var sudoku = QQWing(1)
        self.measure {
            // Put the code you want to measure the time of here.
            sudoku.generatePuzzleSymmetry(Symmetry.ROTATE180)
        }
    }
    
}
