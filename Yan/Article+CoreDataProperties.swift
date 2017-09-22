//
//  Article+CoreDataProperties.swift
//  Yan
//
//  Created by toeinriver on 9/22/17.
//  Copyright © 2017 toeinriver. All rights reserved.
//
//

import Foundation
import CoreData


extension Article {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Article> {
        return NSFetchRequest<Article>(entityName: "Article")
    }

    @NSManaged public var header: String?
    @NSManaged public var content: String?
    @NSManaged public var id: Int32

}
