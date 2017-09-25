import UIKit
import Foundation
import AVFoundation
import SwipeCellKit
import CoreData

extension SwipeAction {
    convenience init(style: SwipeCellKit.SwipeActionStyle, title: String?) {
        self.init(style: style, title: title, handler: {action, indexPath in })
    }
}

class MainViewController:  UITableViewController, SwipeTableViewCellDelegate {

    var player: AVAudioPlayer?
    var lastIndex = 0
    var articleManager: ArticleManager?
    var results: [NSManagedObject?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SwipeTableViewCell.self, forCellReuseIdentifier: "cell")
        fetchData()
        setupUI()
    }
    
    private func getUserId() -> UInt64 {
        return 0 //TODO: Fix this after auth done
    }
    
    private func fetchData() {
        articleManager = ArticleManager(user_id: getUserId())
        articleManager?.retrieve { (error, resultsFromRemote) in
            if let error = error {
                print(error)
            }
            self.results += resultsFromRemote!
            self.tableView.reloadData()
        }
    }
    
    private func setupUI() {
        self.tableView?.separatorStyle = .none
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeTableViewCell
        cell.textLabel?.text = self.results[indexPath.row]?.value(forKey: "header") as? String
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete")
        let flagAction = SwipeAction(style: .default, title: "Flag")
        let moreAction = SwipeAction(style: .default, title: "More")
        return [deleteAction, flagAction, moreAction]
    }
    
    @objc(tableView:didSelectRowAtIndexPath:)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let avc = mainStoryboard.instantiateViewController(withIdentifier: "ArticleVC") as! ArticleViewController
        avc.parentVC = self
        let currentArticle = FetchArticleResult()
        if let header = self.results[indexPath.row]?.value(forKey: "header") {
            currentArticle.header = header as! String
        }
        else {
            currentArticle.header = ""
        }
        if let content = self.results[indexPath.row]?.value(forKey: "content") {
            currentArticle.content = (content as! String)
        }
        else {
            currentArticle.content = ""
        }
        avc.currentArticle = currentArticle
        self.navigationController!.pushViewController(avc, animated: true)
    }
}

