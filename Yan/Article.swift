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

    init(user_id: Int) {
        self.root = "http://localhost:3000"
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
        Alamofire.request(self.url)
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                callback(response)
        })
        
    }
}
