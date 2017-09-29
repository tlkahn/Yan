import UIKit
import Foundation
import AVFoundation
import SwipeCellKit
import CoreData
import SVProgressHUD
import Locksmith

extension SwipeAction {
    convenience init(style: SwipeCellKit.SwipeActionStyle, title: String?) {
        self.init(style: style, title: title, handler: {action, indexPath in })
    }
}

public class MainViewController:  UITableViewController, SwipeTableViewCellDelegate {

    var player: AVAudioPlayer?
    var lastIndex = 0
    var articleManager: ArticleManager?
    var results: [NSManagedObject?] = []
    var sharedContainer = UserDefaults.init(suiteName: "group.YAN.com.apollomillennium")
    var userId: String?
    var token: String?
    var domain: String?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SwipeTableViewCell.self, forCellReuseIdentifier: "cell")
//        let userId = Locksmith.loadDataForUserAccount(userAccount: "Yan")?["userId"] as! String
//        let token = Locksmith.loadDataForUserAccount(userAccount: "Yan")?["token"] as! String
        setUpState()
        let url = domain! + "/users/\(userId!)/articles"
        articleManager = ArticleManager(userId: userId!, token: token!, url: url)
        fetchData()
        setupUI()
        setupPullToRefresh()
    }
    
    private func setUpState() {
        userId = self.sharedContainer?.value(forKey: "userId") as? String
        token = self.sharedContainer?.value(forKey: "token") as? String
        domain = self.sharedContainer?.value(forKey: "domain") as? String ?? "https://apollomillenniumcapital.com"
    }
    
    func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
//        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
    }
    
    private func fetchData() {
        articleManager?.retrieve { (error, resultsFromLocal) in
            if let error = error {
                print(error)
                self.refreshControl!.endRefreshing()
            }
            self.results = resultsFromLocal!
            self.tableView.reloadData()
//            self.updateBadge()
        }
    }
    
    private func updateBadge() {
//        let newItemCount = self.results.count
//        self.updateTabBarItemBadge(newItemCount)
    }
    
    @objc private func refreshData() {
        articleManager?.retrieveFromRemoteAndSyncWithLocal { (error, resultsFromRemote) in
            if let error = error {
                print(error)
                self.showAlertError("Network Error", message: error.localizedDescription)
                self.refreshControl!.endRefreshing()
            }
            else {
                self.results = resultsFromRemote! + self.results
                self.tableView.reloadData()
                SVProgressHUD.showInfo(withStatus: "\(resultsFromRemote!.count) new entries")
                self.refreshControl!.endRefreshing()
            }
        }
    }
    
//    private func updateTabBarItemBadge(_ count: Int) {
//        if let tabItems = collectionVC?.tabBarController?.tabBar.items as NSArray!
//        {
//            let tabItem = tabItems[0] as! UITabBarItem
//            tabItem.badgeValue = String(count)
//        }
//    }
    
    private func setupUI() {
        self.tableView?.separatorStyle = .none
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeTableViewCell
        cell.textLabel?.text = self.results[indexPath.row]?.value(forKey: "header") as? String
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete")
        let flagAction = SwipeAction(style: .default, title: "Flag")
        let moreAction = SwipeAction(style: .default, title: "More")
        return [deleteAction, flagAction, moreAction]
    }
    
    @objc(tableView:didSelectRowAtIndexPath:)
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

