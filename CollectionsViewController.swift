//
//  CollectionsViewController.swift
//  Yan
//
//  Created by toeinriver on 9/23/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import Foundation
import UIKit

class CollectionsViewController: UITableViewController {
    var collection: [String] = ["Shared with Yan"]
    var navVC: UINavigationController?
    
    override func viewDidLoad() {
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.collection[indexPath.row]
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.collection.count
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let nextVC = MainViewController()
            nextVC.navVC = self.navVC
            self.navVC?.pushViewController(nextVC, animated: true)
            
        default:
            break
        }
    }
    
}
