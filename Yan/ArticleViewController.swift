//
//  ArticleViewController.swift
//  Yan
//
//  Created by toeinriver on 9/4/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import UIKit
import AVFoundation

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
        self.content.isEditable = false
        self.automaticallyAdjustsScrollViewInsets = false
        self.header.text = parentVC?.results[menuIndex!].value(forKey: "header") as? String
        self.content.text = parentVC?.results[menuIndex!].value(forKey: "content") as? String
        let utterance = AVSpeechUtterance(string: self.content.text)
        utterance.voice = AVSpeechSynthesisVoice.init() //(language: "zh-CN")
        self.parentVC?.synthesizer?.speak(utterance)
    }
    
    override func viewDidLayoutSubviews() {
        self.content.setContentOffset(CGPoint.zero, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (self.parentVC?.synthesizer?.isSpeaking)! {
            self.parentVC?.synthesizer?.stopSpeaking(at: .word)
        }
        super.viewWillDisappear(animated)
    }
}
