//
//  ArticleViewController.swift
//  Yan
//
//  Created by toeinriver on 9/4/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {
    
    @IBOutlet var header: UILabel!
    @IBOutlet var content: UITextView!
    var menuIndex: Int?
    var parentVC: MainViewController?
    
    init(){
        super.init(nibName: "Article", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        print("article VC loaded")
        self.header.text = parentVC?.results[menuIndex!]
        self.content.text = parentVC?.results[menuIndex!]
    }
}
