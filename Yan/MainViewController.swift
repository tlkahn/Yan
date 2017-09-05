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

class MainViewController:  JTFullTableViewController<FetchResult> {

    var player: AVAudioPlayer?
    var lastIndex = 0
    var synthesizer: AVSpeechSynthesizer?
    var articles = Article(user_id: 0) //TODO: Fix this after auth done
    var navVC: UINavigationController?
    
    override func viewDidLoad() {
        print("main VC loaded")
        super.viewDidLoad()
        
        self.synthesizer = AVSpeechSynthesizer()
        
        /*
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
        */
        // print(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask))
        
        // Don't display empty cells
        self.tableView?.tableFooterView = UIView()
        
        // One of the many way to determine the cell for a tableView
        // The tableView is bind to the controller directly in the storyboard, no need to set the delegate and the dataSource
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.tableView?.separatorStyle = .none
        
        // Optional
        // Load nextPageLoaderCell, this view is bind to the controller directly in the nib
        Bundle.main.loadNibNamed("NextPageLoaderCell", owner: self, options: nil)
        
        // Optional
        // Load noResultsView, this view is bind to the controller directly in the nib
        Bundle.main.loadNibNamed("NoResultsView", owner: self, options: nil)
        
        // Optional
        // Load noResultsLoadingView, this view is bind to the controller directly in the nib
        Bundle.main.loadNibNamed("NoResultsLoadingView", owner: self, options: nil)
        
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "MyTestCell")
        
        cell.textLabel?.text = "Row #\(indexPath.row)"
        cell.detailTextLabel?.text = "Subtitle #\(indexPath.row)"
        
        return cell
    }
     */
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.isFetching {
            fetchResults()
        }
    }
    
    override func fetchResults() {
        self.resetResults()
        
        super.fetchResults()
        
        lastIndex = 0
        
        let lastRequestId = self.lastRequestId
        
        articles.retrieve { (error, results) in
            if let error = error {
                self.didFailedToFetchResults(error: error, lastRequestId: lastRequestId)
            }
            else if let results = results {
                self.didFetchResults(results: results as! [FetchResult], lastRequestId: lastRequestId) {
                    self.lastIndex += results.count
                }
            }
        }
    }
    
    override func fetchNextResults() {
        super.fetchNextResults()
        
        let lastRequestId = self.lastRequestId
        
        articles.retrieve(offset: lastIndex) { (error, results) in
            if let error = error {
                self.didFailedToFetchResults(error: error, lastRequestId: lastRequestId)
            }
            else if let results = results {
                self.didFetchNextResults(results: results as! [FetchResult], lastRequestId: lastRequestId) {
                    self.lastIndex += results.count
                }
            }
        }
    }
    
    override func jt_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.results[indexPath.row].header
        return cell
    }
    
    @objc(tableView:didSelectRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let n = indexPath.row
        let avc = ArticleViewController()
        avc.parentVC = self
        avc.menuIndex = n
        self.navVC?.pushViewController(avc, animated: true)
    }


}

