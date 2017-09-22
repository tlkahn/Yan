import UIKit
import SwiftyJSON
import Alamofire
import CoreData
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}

class FetchArticleResult: NSObject {
    var header: String = ""
    var content: String = ""
}

class ArticleManager {

    var url: String
    var root: String
    var userId: String = ""
    var token: String = ""
    var managedContext =
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var topArticleId = ""
    
    init(user_id: Int) {
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
    }

    func retrieve (offset: Int = 0, completion: @escaping ((Error?, [NSManagedObject?]?) -> Void)) {
        var data: [FetchArticleResult?] = []
        
        if !Reachability.isConnectedToNetwork() {
            print("not conncted to network. using local storage")
            self.fetchLocal() { results in
                completion(nil, results)
            }
        }
        else {
            DispatchQueue.main.async() {
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
                                                       in: self.managedContext)!
                        
                        //                var results: [FetchResult?] = []
                        var results: [NSManagedObject?] = []
                        for i in offset..<(offset + pageSize) {
                            //                    results.append(data[i])
                            let article = NSManagedObject(entity: entity,
                                                          insertInto: self.managedContext)
                            article.setValue(data[i]?.header, forKeyPath: "header")
                            article.setValue(data[i]?.content, forKeyPath: "content")
                            do {
                                try self.managedContext.save()
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
        }
    }

    private func fetchRemote (callback: @escaping (DataResponse<Any>)->Void) -> Void {
        Alamofire.request(self.url, method: .get, parameters: ["token": self.token, "topArticleId": self.topArticleId])
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                callback(response)
        })
        
    }
    
    private func fetchLocal(callback: @escaping ([NSManagedObject]?) -> Void) -> Void {
        var articles: [NSManagedObject]?
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Article")

        do {
            articles = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        callback(articles)
    }
}
