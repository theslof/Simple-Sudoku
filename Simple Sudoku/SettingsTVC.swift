//
//  SettingsTVC.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-22.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController {
    @IBOutlet weak var deleteCell: UITableViewCell!
    @IBOutlet weak var themeCell: UITableViewCell!
    @IBOutlet weak var themeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.tableFooterView = UIView()
        themeSwitch.isOn = isDarkTheme()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return themeCell
        }
        return deleteCell
    }

    @IBAction func deleteDataBtn(_ sender: UIButton) {
        let ac = UIAlertController(title: "DELETE", message: "This will delete ALL data permanently. Are you sure?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            self.navigationController?.popToRootViewController(animated: true)
        }))
        ac.addAction(UIAlertAction(title: "No", style: .default))
        self.present(ac, animated: true)
    }
    
    @IBAction func themeSwitchTapped(_ sender: UISwitch) {
        setDarkTheme(sender.isOn)
    }
}
