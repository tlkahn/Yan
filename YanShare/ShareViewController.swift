//
//  ShareViewController.swift
//  YanShare
//
//  Created by toeinriver on 9/4/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Alamofire
import SwiftyJSON
import Locksmith

class ShareViewController: SLComposeServiceViewController {
    
    let sharedContainer = UserDefaults(suiteName: "group.YAN.com.apollomillennium")
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        let domain = sharedContainer!.value(forKey: "domain") as? String ?? "https://apollomillenniumcapital.com"
//        if let userId = Locksmith.loadDataForUserAccount(userAccount: "Yan")?["email"] {
        if let userId = sharedContainer!.value(forKey: "userId") {
            let extensionItem = extensionContext?.inputItems.first as! NSExtensionItem
            let itemProvider = extensionItem.attachments?.first as! NSItemProvider
            let propertyList = String(kUTTypePropertyList)
            if itemProvider.hasItemConformingToTypeIdentifier(propertyList) {
                itemProvider.loadItem(forTypeIdentifier: propertyList, options: nil, completionHandler: { (item, error) -> Void in
                    guard let dictionary = item as? NSDictionary else { return }
                    DispatchQueue.main.async {
                        if let jsResults = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary
                        {
                            let jsURL = jsResults["URL"] as? String
                            print("jsURL: ", jsURL!)
                            let parameters: Parameters = ["token": "97f9a5ba1c3b4fb6f00b3bfa545bdb5f", "url": jsURL!, "userId": userId]
                            print("parameters", parameters)
                            print("sending reqeust to diffbot API")
                            Alamofire.request("https://api.diffbot.com/v3/article", parameters: parameters)
                                .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                                    if let data = response.data {
                                        let json = JSON(data: data)
                                        print("text: ", json["objects"][0]["text"])
                                        print("title: ", json["objects"][0]["title"])
                                        print("userId: ", userId)
                                        let p: Parameters = ["header":json["objects"][0]["title"], "content": json["objects"][0]["text"], "userId": userId]
                                        Alamofire.request(domain + "/articles", method: .post, parameters: p).responseJSON(completionHandler: {
                                            (response: DataResponse) -> Void in
                                            print("successful sync web content to server")
                                            print(response)
                                            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                                        })
                                    }
                                })
                        }
                    }
                })
            } else {
                print("error")
            }
        }
        else {
            print("app is not logged in")
        }
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    }
    
    func sharedApplication() throws -> UIApplication {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            
            responder = responder?.next
        }
        
        throw NSError(domain: "UIInputViewController+sharedApplication.swift", code: 1, userInfo: nil)
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
}
