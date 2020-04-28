//
//  CacheTest.swift
//  memriTests
//
//  Created by Ruben Daniels on 3/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri


class CacheTest: XCTestCase {
    var testCache:Cache = Cache(PodAPI("test"))

    override func setUp() {
        // reset cache
        testCache = Cache(PodAPI("test"))
        testCache.scheduleUIUpdate = {_ in }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCacheInstall() {
        // Also tests getItemById
        testCache.install()
        XCTAssertTrue(testCache.realm.objects(Country.self).count > 0 )
    }
    
    func testGetItem(){
        testCache.install()
        XCTAssertEqual(testCache.getItemById("country", "Aruba")?.getString("name"), "Aruba")
    }
    
    func testEmptyQuery() {
        testCache.query(QueryOptions(query: "")){error, items in
            XCTAssertEqual(items, nil)
        }
    }
    
    func testTypeQuery() {
        testCache.install()
        
        for dtype in DataItemFamily.allCases{
            testCache.query(QueryOptions(query: dtype.rawValue)){error, items in
                if let result = items{
                    XCTAssertTrue(result.allSatisfy{item in item.genericType == dtype.rawValue })
                }else{
                    XCTFail()
                }
            }
        }
    }
    
    func testFilteredQuery() {
        //TODO
    }
    
    func testSortedQuery() {
        //TODO
    }
    
    func testParseQuery(){
        let (type1, filter1) = testCache.parseQuery("note")
        XCTAssertTrue(type1 == "note"); XCTAssertTrue(filter1 == nil)
        
        let (type2, filter2) = testCache.parseQuery("* x<40")
        XCTAssertTrue(type2 == "*"); XCTAssertTrue(filter2 == "x<40")

        let (type3, filter3) = testCache.parseQuery("note x == 40")
        XCTAssertTrue(type3 == "note"); XCTAssertTrue(filter3 == "x == 40")
    }
    
    func testGetResultSet(){
        testCache.install()
        // TODO: not sure what this should test yet
        let result = testCache.getResultSet(QueryOptions(query: "*"))
    }
    
    func testAddToCache(){
        let note = Note()
        let cachedNote = try! testCache.addToCache(note)
        // TODO: what to test here
    }
    
    func testDelete(){
        testCache.install()
        let item = testCache.getItemById("country", "Aruba")
        testCache.delete(item!)
        let item2 = testCache.getItemById("country", "Aruba")
        XCTAssertTrue(item2?.deleted == true || item2 == nil)
    }
    
    func testDeleteMulti(){
        testCache.install()
        let items = [testCache.getItemById("country", "Aruba")!,
                     testCache.getItemById("country", "Antarctica")!]
        
        testCache.delete(items)
        
        let items2 = [testCache.getItemById("country", "Aruba"),
                      testCache.getItemById("country", "Antarctica")]
        
        XCTAssertTrue(items2.allSatisfy{$0?.deleted == true || $0 == nil})
    }
    
    func testDuplicate(){
        testCache.install()
        let item = testCache.getItemById("country", "Aruba")
        let copy = testCache.duplicate(item!)
        let cls = item!.getType()

        for prop in item!.objectSchema.properties{
            if prop.name != cls.primaryKey(){
                item!.isEqualProperty(prop.name, copy)
            }
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
