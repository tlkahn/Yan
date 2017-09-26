//
//  TabViewController.swift
//  Yan
//
//  Created by toeinriver on 9/24/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import UIKit

class TabViewController: UITabBarController {
    override func viewDidLoad() {
        
        let nextVC = collectionVC
        let navVC = UINavigationController.init(rootViewController: nextVC!)
        navVC.viewControllers = [nextVC!]
        navVC.navigationBar.topItem?.title = "Yan"
        
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
        let connectMoreVC = mainStoryboard.instantiateViewController(withIdentifier: "AddAccountVC") as! AddAccountTableViewController
        let navVC2 = UINavigationController.init(rootViewController: connectMoreVC)
        navVC2.viewControllers = [connectMoreVC]
        navVC2.navigationBar.topItem?.title = "Connect"
        
        self.viewControllers = [navVC, navVC2]
        
        self.tabBar.items?[0].title = "Collections"
        self.tabBar.items?[1].title = "Connections"
        self.tabBar.items?[0].image = UIImage(named: "Unread")
        self.tabBar.items?[1].image = UIImage(named: "More")
    }
}
