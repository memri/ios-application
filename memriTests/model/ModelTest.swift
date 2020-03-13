//
//  Model.swift
//  memriTests
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri


class ModelTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitDataItems(){
        let items: [DataItem] = [DataItem(uid: "0x01", type: "note", predicates: nil, properties: ["title": "my first note", "content": "my first note"]),
                    DataItem(uid: "0x02", type: "note", predicates: nil, properties: ["title": "my second note",                         "content": "my second note"])]


        XCTAssert(items[0].type == "note" && items[1].type == "note")
        XCTAssert(items[0].properties["title"] == "my first note")
    }
    
    func testDeserializeDataItemsFromJSON() {
        var items = try! DataItem.from_json(file: "test_dataItems")
        print(items[0].uid)
        XCTAssert(items[0].uid == "0x01" && items[1].uid == "0x02")
        XCTAssert(items[0].type == "note" && items[1].type == "note")
        XCTAssert(items[0].properties["title"] == "my first note")
    }
    
    func testInitSearchResult(){
        let items = try! DataItem.from_json(file: "test_dataItems")
        let sr = SearchResult.fromDataItems(items)
        XCTAssert(sr.data[0].uid == "0x01" && sr.data[1].uid == "0x02")
    }
    
    func testInitCache(){
        let key = "mytestkey"
        let testPodAPI = PodAPI(key)
        let cache = Cache(testPodAPI)
    }
    
    func testQueryCache(){
        let key = "mytestkey"
        let testPodAPI = PodAPI(key)
        let cache = Cache(testPodAPI)
        let sr = cache.getByType(type: "note")!
        XCTAssert(sr.data[0].uid == "0x01" && sr.data[1].uid == "0x02")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
