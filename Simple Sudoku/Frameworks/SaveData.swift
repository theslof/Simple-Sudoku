//
//  SaveData.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-03.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation

struct defaultsKeys {
    static let CURRENT_GAME = "currentGame"
}

func saveCurrentGame(sudoku: Sudoku){
    let defaults = UserDefaults.standard
    if let data = try? JSONEncoder().encode(sudoku) {
        defaults.set(data, forKey: defaultsKeys.CURRENT_GAME)
    } else {
        print("Error: Could not save sudoku")
    }
}

func loadCurrentGame() -> Sudoku? {
    let defaults = UserDefaults.standard
    if let currentGame = defaults.value(forKey: defaultsKeys.CURRENT_GAME) as? Data {
        return try? JSONDecoder().decode(Sudoku.self, from: currentGame)
    }
    return nil
}
