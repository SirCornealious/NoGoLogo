//
//  APIKey+CoreDataProperties.swift
//  NoGoLogo
//
//  Created by Jared Maxwell on 8/27/25.
//
//

public import Foundation
public import CoreData


public typealias APIKeyCoreDataPropertiesSet = NSSet

extension APIKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<APIKey> {
        return NSFetchRequest<APIKey>(entityName: "APIKey")
    }

    @NSManaged public var key: String?
    @NSManaged public var type: String?

}

extension APIKey : Identifiable {

}
