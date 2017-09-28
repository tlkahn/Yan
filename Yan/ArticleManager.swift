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

enum NetworkError: Error {
    case timeout
}

protocol ArticleManagerDelegate {
    func fetchRemote(callback: @escaping (NetworkError?, DataResponse<Any>?)->Void) -> Void
    func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void
}

class YanShareArticleManagerDelegate : ArticleManagerDelegate {
    
    var articleManager: ArticleManager?
    var alamoFireManager: SessionManager?
    
    init(_ articleManager: ArticleManager) {
        self.articleManager = articleManager
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 4 // seconds
        configuration.timeoutIntervalForResource = 4
        alamoFireManager = Alamofire.SessionManager(configuration: configuration)
    }
 
    func fetchRemote (callback: @escaping (NetworkError?, DataResponse<Any>?)->Void) -> Void {
        print("fetching data from \(self.articleManager!.url)")
        let userId = UserDefaults(suiteName: "group.YAN.com.apollomillennium")!
        print("current userId is \(userId)")
        alamoFireManager?.request(self.articleManager!.url, method:.get, parameters:["token": self.articleManager!.token, "topArticleId": self.articleManager!.topArticleId ?? "", "userId": userId])
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                switch (response.result) {
                case .success:
                    print("fetch data from server successful.")
                    callback(nil, response)
                    break
                case .failure(let error):
                    if error._code == NSURLErrorTimedOut {
                        callback(.timeout, nil)
                    }
                    else {
                        print("\n\nAuth request failed with error:\n \(error)")
                    }
                    break
                }
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
    var userId: String = ""
    var token: String = ""
    var topArticleId: String?
    var delegate: ArticleManagerDelegate?
    
    init(userId: String, token: String, url: String) {
        self.userId = userId
        self.token = token
        self.url = url
        self.delegate = YanShareArticleManagerDelegate(self)
        if let aid = UserDefaults.standard.string(forKey: "topArticleId") {
            topArticleId = aid
        }
        else {
            topArticleId = ""
        }
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
    
    func retrieveFromRemoteAndSyncWithLocal (offset: Int = 0, completion: @escaping ((Error?, [NSManagedObject?]?) -> Void)) {
        self.syncServerAndUpdateLocal(offset: offset, completion: completion)
    }
    
    private func saveTopArticleId(_ topArticleId: String) {
        UserDefaults.standard.set(topArticleId, forKey: "topArticleId")
    }
    
    public func syncServerAndUpdateLocal(offset: Int = 0, completion: @escaping ((Error?, [NSManagedObject?]?) -> Void)) {
        var data: [FetchArticleResult?] = []
        self.fetchRemote() { (error: NetworkError?, response: DataResponse?) in
            
            if let e = error {
                return completion(e, nil)
            }
            
            let json = JSON(data: (response?.data)!)
            if json.count > 0 {
                self.topArticleId = json[0]["_id"].string!
                self.saveTopArticleId(self.topArticleId!)
                print("top Article Id: ", self.topArticleId!)
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

    private func fetchRemote (callback: @escaping (NetworkError?, DataResponse<Any>?)->Void) -> Void {
        self.delegate?.fetchRemote(callback: callback)
    }
    
    private func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void {
        self.delegate?.fetchLocal(callback: callback)
    }
}
