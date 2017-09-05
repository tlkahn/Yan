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

class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
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
                        let parameters: Parameters = ["token": "6b8979cf259d058f1423274e146c06e2", "url": jsURL!]
                        print("parameters", parameters)
                        print("sending reqeust to diffbot API")
                        Alamofire.request("https://api.diffbot.com/v3/article", parameters: parameters)
                            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                                if let data = response.data {
                                    let json = JSON(data: data)
                                    print("text: ", json["objects"][0]["text"])
                                    print("title: ", json["objects"][0]["title"])
                                    let p: Parameters = ["header":json["objects"][0]["title"], "content": json["objects"][0]["text"]]
                                    Alamofire.request(__domain__ + "/articles", method: .post, parameters: p).responseJSON(completionHandler: {
                                        (response: DataResponse) -> Void in
                                        print(response)
                                    })
                                }
                            })
                    }
                }
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            })
        } else {
            print("error")
        }
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
}
