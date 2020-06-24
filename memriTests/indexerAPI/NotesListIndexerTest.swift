//
//  NotesListIndexerTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 24/06/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

class NotesListIndexerTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        
        let api = IndexerAPI()
        
        let indexer = Indexer(name: "Lists indexer")
        
        let indexerInstance =   IndexerInstance()
        
        let jsonData = try jsonDataFromFile("list_indexer_data")
        let items:[DataItem] = try MemriJSONDecoder.decode(family:DataItemFamily.self, from:jsonData)
        
        api.execute(<#T##indexerInstance: IndexerInstance##IndexerInstance#>, <#T##items: [DataItem]##[DataItem]#>)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
