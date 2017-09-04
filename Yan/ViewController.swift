//
//  ViewController.swift
//  Yan
//
//  Created by toeinriver on 9/4/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class ViewController: UIViewController {

    var player: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "郭永是世界上最棒的！")
        utterance.voice = AVSpeechSynthesisVoice.init(language: "zh-CN")
        synthesizer.speak(utterance)

        let soundPath = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: soundPath)
            guard let player = player else { return }

            player.play()
        } catch let error as NSError {
            print(error.description)
        }
        // print(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }


}

