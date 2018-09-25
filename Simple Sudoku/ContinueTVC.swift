//
//  ContinueTVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-22.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class ContinueTVC: UITableViewController {

    var gameIndex: [String] = []
    var sudoku: Sudoku?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.dataSource = self
        tableView.delegate = self

        gameIndex = loadGames()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameIndex.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameInfoRow", for: indexPath)

        cell.detailTextLabel?.text = gameIndex[indexPath.row]

        BQ {
            if let metaData = loadMetaDataFor(seed: self.gameIndex[indexPath.row]) {
                MQ {
                    cell.textLabel?.text = "\(metaData.difficulty), \(metaData.solved)/81 solved"
                }
            }
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            clearSavedGameFor(seed: gameIndex[indexPath.row])
            gameIndex.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sudoku = loadGameFor(seed: gameIndex[indexPath.row])
        self.performSegue(withIdentifier: "continueGameSegue", sender: self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let dest = segue.destination as? GameBoardVC {
            dest.sudoku = sudoku ?? Sudoku()
        }
    }
}
