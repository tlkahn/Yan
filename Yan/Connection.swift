//
//  Connection.swift
//  Yan
//
//  Created by toeinriver on 9/6/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//

import Foundation
import UIKit

class Connection {
    var image: UIImage?
    var title: String?
    
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }
    
    class func all() -> [Connection] {
        var result = [Connection]()
        result = [
            Connection(image: UIImage(named: "Mail")!, title: "Mail"),
            Connection(image: UIImage(named: "Evernote")!, title: "Evernote"),
            Connection(image: UIImage(named: "Fb")!, title: "Facebook"),
            Connection(image: UIImage(named: "Twtr")!, title: "Twitter"),
            Connection(image: UIImage(named: "Safari")!, title: "Safari Reading List")
        ]
        return result
    }
    
}
