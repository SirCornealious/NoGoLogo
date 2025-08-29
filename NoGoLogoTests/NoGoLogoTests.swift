//
//  NoGoLogoTests.swift
//  NoGoLogoTests
//
//  Created by Jared Maxwell on 8/26/25.
//
import XCTest
import CoreData
@testable import NoGoLogo

class NoGoLogoTests: XCTestCase {
    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }

    func testSaveAPIKey() {
        let context = persistenceController.container.viewContext
        let apiKey = APIKey(context: context)
        apiKey.key = "test-key"
        try? context.save()

        let fetchRequest: NSFetchRequest<APIKey> = APIKey.fetchRequest()
        let keys = try? context.fetch(fetchRequest)
        XCTAssertEqual(keys?.count, 1)
        XCTAssertEqual(keys?.first?.key, "test-key")
    }
}
