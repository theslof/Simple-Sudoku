//
//  Save?Data.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-03.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation

struct defaultsKeys {
    static let CURRENT_GAMES = "currentGames"
}

struct GameMetaData: Codable {
    let difficulty: String
    let symmetry: String
    let solved: Int
}

func saveGame(sudoku: Sudoku){
    debugPrint("Trying to save game...")
    let defaults = UserDefaults.standard
    if let data = try? PropertyListEncoder().encode(sudoku) {
        debugPrint("Encoding successful, attempting to save data: \(data)")
        defaults.set(data, forKey: String(sudoku.seed))
    } else {
        debugPrint("Error: Could not save sudoku")
    }
    let metaData = GameMetaData(difficulty: sudoku.difficulty, symmetry: sudoku.symmetry, solved: sudoku.getProgress())
    if let data = try? PropertyListEncoder().encode(metaData) {
        debugPrint("Encoding successful, attempting to save meta data: \(data)")
        defaults.set(data, forKey: "\(sudoku.seed)_metadata")
    } else {
        debugPrint("Error: Could not save metadata")
    }
}

func loadGameFor(seed: String) -> Sudoku? {
    debugPrint("Trying to load game: \(seed)")
    let defaults = UserDefaults.standard
    if let currentGame = defaults.value(forKey: seed) as? Data {
        debugPrint("Game data found! Attempting to decode data...")
        do { return try PropertyListDecoder().decode(Sudoku.self, from: currentGame) }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    debugPrint("Loading failed!")
    return nil
}

func loadMetaDataFor(seed: String) -> GameMetaData? {
    debugPrint("Trying to load metadata for: \(seed)")
    let defaults = UserDefaults.standard
    if let metaData = defaults.value(forKey: "\(seed)_metadata") as? Data {
        debugPrint("Game data found! Attempting to decode data...")
        do { return try PropertyListDecoder().decode(GameMetaData.self, from: metaData) }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    debugPrint("Loading failed!")
    return nil
}

func loadGames() -> [String] {
    debugPrint("Fetching list of saved games...")
    let defaults = UserDefaults.standard
    return defaults.stringArray(forKey: defaultsKeys.CURRENT_GAMES) ?? [String]()
}

func addGame(seed: String) {
    let defaults = UserDefaults.standard
    var games = loadGames()
    if !games.contains(seed) {
        games.append(seed)
        defaults.set(games, forKey: defaultsKeys.CURRENT_GAMES)
        debugPrint("Game added to Saved Games")
    }
}

func clearSavedGameFor(seed: String) {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: seed)
    defaults.removeObject(forKey: "\(seed)_metadata")
    var games = loadGames()
    if let index = games.index(of: seed) {
        games.remove(at: index)
        defaults.set(games, forKey: defaultsKeys.CURRENT_GAMES)
    }
}

func clearAllSavedGames() {
    for game in loadGames() {
        clearSavedGameFor(seed: game)
    }
}