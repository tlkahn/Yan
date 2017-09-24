//
//  MailsTableViewController.swift
//  PostalDemo
//
//  Created by Kevin Lefevre on 06/06/2016.
//  Copyright © 2017 Snips. All rights reserved.
//

import UIKit
import Postal
import Result
import SVProgressHUD

class MailsTableViewController: UITableViewController {
    var configuration: Configuration!
    
    fileprivate lazy var postal: Postal = Postal(configuration: self.configuration)
    fileprivate var messages: [FetchResult] = []
    var navVC: UINavigationController?
}

// MARK: - View lifecycle

extension MailsTableViewController {
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        // Do connection
        postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
            switch result {
            case .success: // Fetch 50 last mails of the INBOX
                self?.postal.fetchLast("INBOX", last: 50, flags: [ .fullHeaders, .body ], onMessage: { message in
                    self?.messages.insert(message, at: 0)
                    }, onComplete: { error in
                        if let error = error {
                            self?.showAlertError("Fetch error", message: (error as NSError).localizedDescription)
                        } else {
                            SVProgressHUD.showSuccess(withStatus: "Done")
                            self?.tableView.reloadData()
                        }
                })

            case .failure(let error):
                self?.showAlertError("Connection error", message: (error as NSError).localizedDescription)
            }
        })
    }
}

// MARK: - Table view data source

extension MailsTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell", for: indexPath)

        let message = messages[indexPath.row]
        
        cell.textLabel?.text = message.header?.subject
        cell.detailTextLabel?.text = "UID: #\(message.uid)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
        let avc = mainStoryboard.instantiateViewController(withIdentifier: "ArticleVC") as! ArticleViewController
        avc.parentVC = self
        let currentArticle = FetchArticleResult()
        currentArticle.header = (messages[indexPath.row].header?.subject)!
//        currentArticle.content = (messages[indexPath.row].body?.description)!
        self.postal.fetchMessages("INBOX", uids: [Int(messages[indexPath.row].uid)], flags: [.body], onMessage: {
            message in
                let _ = message.body?.allParts.flatMap({p in
                    let dataString = String(data:(p.data?.decodedData)!, encoding: String.Encoding.utf8) // String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                    var str = dataString?.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
                    str = str?.replacingOccurrences(of: "[\n\r\"\']", with: " ", options: String.CompareOptions.regularExpression, range: nil)
                    str = str?.replacingOccurrences(of: "([\\.\\#].+)(\\{[^}]+\\})", with: " ", options: String.CompareOptions.regularExpression, range: nil)
                    currentArticle.content += str!
                    return str!
                })
        }, onComplete: {_ in
            avc.currentArticle = currentArticle
            self.navVC?.pushViewController(avc, animated: true)
        })
    }
}

// MARK: - Helper

private extension MailsTableViewController {
    
}
