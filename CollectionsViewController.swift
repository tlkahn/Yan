//
//  CollectionsViewController.swift
//  Yan
//
//  Created by toeinriver on 9/23/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import Foundation
import UIKit
import Postal

class CollectionsViewController: UITableViewController {
    
    override func viewDidLoad() {
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = collectionSources[indexPath.row]
        return cell
    }

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionSources.count
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let nextVC = mainYanShareVC
            self.navigationController!.pushViewController(nextVC!, animated: true)
        default:
            let nextVC = MailsTableViewController()
            if let data = UserDefaults.standard.data(forKey: collectionSources[indexPath.row]) {
                nextVC.configuration = Configuration.decode(data: data)
                self.navigationController!.pushViewController(nextVC, animated: true)
            } else {
                print("There is an issue")
            }
            break
        }
    }
    
}
