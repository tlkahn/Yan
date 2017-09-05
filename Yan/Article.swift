import UIKit
import SwiftyJSON
import Alamofire

class FetchResult {
    var header: String = ""
    var content: String = ""
}

class Article {

    var url: String
    var root: String
    var userId: String = ""
    var token: String = ""
    
    init(user_id: Int) {
        self.root = "http://localhost:3000"
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

    func retrieve (offset: Int = 0, completion: @escaping ((Error?, [Any]?) -> Void)) {
        var data: [FetchResult?] = []
        DispatchQueue.main.async() {
            self.fetch() {
                (response: DataResponse) in
                    let json = JSON(data: response.data!)
                    for (_, subJson) in json {
                        let fetchResult = FetchResult()
                        fetchResult.header = subJson["header"].string!
                        fetchResult.content = subJson["content"].string!
                        data.append(fetchResult)
                    }

                    var pageSize = 10
                    
                    if((offset + pageSize) >= data.count) {
                        pageSize = data.count - offset
                    }
                    
                var results: [FetchResult?] = []
                    for i in offset..<(offset + pageSize) {
                        results.append(data[i])
                    }
                    completion(nil, results)
            }
        }
 
    }

    private func fetch (callback: @escaping (DataResponse<Any>)->Void) -> Void {
        Alamofire.request(self.url, method: .get, parameters: ["token": self.token])
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                callback(response)
        })
        
    }
}
