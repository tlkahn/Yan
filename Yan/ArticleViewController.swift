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
    var currentArticle: FetchArticleResult?
    var parentVC: UIViewController?
    var synthesizer: AVSpeechSynthesizer?
    var navVC: UINavigationController?
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        print("article VC loaded")
        self.content?.isEditable = false
        self.automaticallyAdjustsScrollViewInsets = false
        self.header.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
        self.header.numberOfLines = 0
        
        self.header.text = currentArticle?.header
        self.content.text = currentArticle?.content
        
        let utterance = AVSpeechUtterance(string: (self.content?.text)!)
        utterance.voice = AVSpeechSynthesisVoice.init() //(language: "zh-CN")
        self.synthesizer = AVSpeechSynthesizer()
        self.synthesizer?.speak(utterance)
        
    }
    
    override func viewDidLayoutSubviews() {
        self.content?.setContentOffset(CGPoint.zero, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (self.synthesizer?.isSpeaking)! {
            self.synthesizer?.stopSpeaking(at: .word)
        }
        super.viewWillDisappear(animated)
    }
}
