import UIKit
import Foundation
import AVFoundation
import SwipeCellKit

class ConnectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView?
    var connections: [Connection]?
    
    override func viewDidLoad() {
        print("connection VC loaded")
        view.backgroundColor = UIColor.white
        let topOffset = CGFloat(40.0)
        tableView = UITableView(frame: CGRect(origin: CGPoint(x: 0, y: topOffset), size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - topOffset)))
        tableView?.register(SwipeTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView?.separatorStyle = .none
        tableView?.delegate = self
        tableView?.dataSource = self
        connections = Connection.all()
        view.addSubview(self.tableView!)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50)
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (connections?.count)!
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeTableViewCell
        cell.imageView?.image = connections?[indexPath.row].image
        cell.textLabel?.text = connections?[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            print("connection to mail.")
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let nextVC = mainStoryboard.instantiateViewController(withIdentifier: "AddAccountVC") as! AddAccountTableViewController
            self.navigationController!.pushViewController(nextVC, animated: true)
            
        default:
            print("connection default")
        }
    }

}
