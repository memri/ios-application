//
// LabelIndexerNotesTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class LabelIndexerNotesTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let indexerAPI = IndexerAPI()

        let indexer = Indexer(name: "Label indexer",
                              itemDescription: "Adds labels to notes based on their content",
                              query: "Note", runDestination: "ios")
        let indexerInstance = IndexerRun(name: indexer.name, indexer: indexer)

        let jsonData = try jsonDataFromFile("label_indexer_data")
        let items: [Item] = try MemriJSONDecoder.decode(family: ItemFamily.self, from: jsonData)

        try indexerAPI.execute(indexerInstance, items)

        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
