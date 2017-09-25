import UIKit
import SwiftyJSON
import Alamofire
import CoreData
import SVProgressHUD

var __globalManagedContext__ = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

class FetchArticleResult: NSObject {
    var header: String = ""
    var content: String = ""
}

protocol ArticleManagerDelegate {
    func fetchRemote(callback: @escaping (DataResponse<Any>)->Void) -> Void
    func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void
}

class YanShareArticleManagerDelegate : ArticleManagerDelegate {
    
    var articleManager: ArticleManager?
    
    init(_ articleManager: ArticleManager) {
        self.articleManager = articleManager
    }
    
    func fetchRemote (callback: @escaping (DataResponse<Any>)->Void) -> Void {
        Alamofire.request(self.articleManager!.url, method: .get, parameters: ["token": self.articleManager!.token, "topArticleId": self.articleManager!.topArticleId])
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                callback(response)
            })
    }
    
    func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void {
        var articles: [NSManagedObject]?
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Article")
        do {
            articles = try __globalManagedContext__.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        callback(articles)
    }
}

class ArticleManager {

    var url: String
    var root: String
    var userId: String = ""
    var token: String = ""
    var topArticleId = ""
    var delegate: ArticleManagerDelegate?
    
    init(user_id: UInt64) {
        self.root = __domain__
        if let tokenData = UserDefaults.standard.value(forKey: "token") as? NSData {
            self.token = NSKeyedUnarchiver.unarchiveObject(with: tokenData as Data) as! String
        }
        if let userIdData = UserDefaults.standard.value(forKey: "userId") as? NSData {
            self.userId = NSKeyedUnarchiver.unarchiveObject(with: userIdData as Data) as! String
        }
        self.userId = UserDefaults.standard.value(forKey: "userId") as! String
        self.token = UserDefaults.standard.value(forKey: "token") as! String
        self.url = self.root + "/users/\(user_id)/articles"
        self.delegate = YanShareArticleManagerDelegate(self)
    }

    func retrieve (offset: Int = 0, completion: @escaping ((Error?, [NSManagedObject?]?) -> Void)) {
        
        if !Reachability.isConnectedToNetwork() {
            print("not conncted to network. using local storage")
            self.fetchLocal() { results in
                SVProgressHUD.showInfo(withStatus: "You're offline. Using local data.")
                completion(nil, results)
            }
        }
        else {
            DispatchQueue.main.async() {
                self.fetchLocal() {results in
                    if results?.count == 0 {
                        self.syncServerAndUpdateLocal(offset: offset, completion: completion)
                    }
                    else {
                        completion(nil, results)
                    }
                }
            }
        }
    }
    
    public func syncServerAndUpdateLocal(offset: Int = 0, completion: @escaping ((Error?, [NSManagedObject?]?) -> Void)) {
        var data: [FetchArticleResult?] = []
        self.fetchRemote() {
            (response: DataResponse) in
            let json = JSON(data: response.data!)
            if json.count > 0 {
                self.topArticleId = json[0]["_id"].string!
                print("top Article Id: ", self.topArticleId)
                for (_, subJson) in json {
                    let fetchResult = FetchArticleResult()
                    fetchResult.header = subJson["header"].string!
                    fetchResult.content = subJson["content"].string!
                    data.append(fetchResult)
                }
                
                var pageSize = 10
                
                if((offset + pageSize) >= data.count && pageSize > 0) {
                    pageSize = data.count - offset
                }
                
                let entity =
                    NSEntityDescription.entity(forEntityName: "Article",
                                               in: __globalManagedContext__)!
                
                var results: [NSManagedObject?] = []
                for i in offset..<(offset + pageSize) {
                    let article = NSManagedObject(entity: entity,
                                                  insertInto: __globalManagedContext__)
                    article.setValue(data[i]?.header, forKeyPath: "header")
                    article.setValue(data[i]?.content, forKeyPath: "content")
                    do {
                        try __globalManagedContext__.save()
                        results.append(article)
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
                completion(nil, results)
            }
            else {
                completion(nil, [])
            }
        }
    }

    private func fetchRemote (callback: @escaping (DataResponse<Any>)->Void) -> Void {
        self.delegate?.fetchRemote(callback: callback)
    }
    
    private func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void {
        self.delegate?.fetchLocal(callback: callback)
    }
}
