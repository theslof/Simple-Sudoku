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
    debugPrint("Trying to save game...")
    let defaults = UserDefaults.standard
    if let data = try? PropertyListEncoder().encode(sudoku) {
        debugPrint("Encoding successful, attempting to save data: \(data)")
        defaults.set(data, forKey: defaultsKeys.CURRENT_GAME)
    } else {
        debugPrint("Error: Could not save sudoku")
    }
}

func loadCurrentGame() -> Sudoku? {
    debugPrint("Trying to load game...")
    let defaults = UserDefaults.standard
    if let currentGame = defaults.value(forKey: defaultsKeys.CURRENT_GAME) as? Data {
        debugPrint("Game data found! Attempting to decode data...")
        do { return try PropertyListDecoder().decode(Sudoku.self, from: currentGame) }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    debugPrint("Loading failed!")
    return nil
}

func clearSavedGame() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: defaultsKeys.CURRENT_GAME)
}