//
//  ItemTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 30/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri


class ItemTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDeserializeItem(){
        let data = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item: Item = try! MemriJSONDecoder.decode(Item.self, from: data)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        XCTAssertEqual(item.get("memriID"), "0x012345")
        XCTAssertEqual(item.get("starred"), true)
        XCTAssertEqual(item.get("dateCreated", type: Date.self)!.timeIntervalSince1970, 1586517071)
        XCTAssertEqual(item.get("version"), 10)
    }
    
    func testGetString(){
        let data = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item: Item = try! MemriJSONDecoder.decode(Item.self, from: data)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        XCTAssertEqual(item.getString("memriID"), "0x012345")
        XCTAssertEqual(item.getString("starred"), "true")
        XCTAssertEqual(item.getString("dateCreated"), "2020/04/10 13:11")
        XCTAssertEqual(item.getString("version"), "10")
    }

    func testGetType() throws {
        let note = Note()
        let n = note.getType()!
        XCTAssertEqual("\(n)", "Note")
    }
    
    func testSet() throws {
        let item = Item()
        XCTAssertEqual(item.version, 0)
        item.set("version", 1)
        XCTAssertEqual(item.version, 1)
    }
    
    func testToggle() throws {
        let item = Item()
        XCTAssertEqual(item.starred, false)
        item.toggle("starred")
        XCTAssertEqual(item.starred, true)
    }
    
    func testMerge(){
        let data1 = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item1: Item = try! MemriJSONDecoder.decode(Item.self, from: data1)
        
        let data2 = Data("""
            {
                "memriID": "333",
                "starred": false
            }
            """.utf8
        )
        let item2: Item = try! MemriJSONDecoder.decode(Item.self, from: data2)
        
        item1.merge(item2)
        
        XCTAssertEqual(item1.get("memriID"), "333")
        XCTAssertEqual(item1.get("starred"), false)
        XCTAssertEqual(item1.get("dateCreated", type: Date.self)!.timeIntervalSince1970, 1586517071)
        XCTAssertEqual(item1.get("version"), 10)
    }
    
    func testSafeMergeVersion(){
        let data1 = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item1: Item = try! MemriJSONDecoder.decode(Item.self, from: data1)
        
        let data2 = Data("""
            {
                "memriID": "333",
                "starred": false,
                "version": 11
            }
            """.utf8
        )
        let item2: Item = try! MemriJSONDecoder.decode(Item.self, from: data2)
        
        XCTAssertEqual(item1.safeMerge(item1), false)
        XCTAssertEqual(item2.safeMerge(item1), false)
        XCTAssertEqual(item1.safeMerge(item2), true)
    }
    
    func testSafeMergeUpdateFields(){
        let data1 = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item1: Item = try! MemriJSONDecoder.decode(Item.self, from: data1)
        
        let data2 = Data("""
            {
                "memriID": "333",
                "starred": false,
                "version": 11
            }
            """.utf8
        )
        let item2: Item = try! MemriJSONDecoder.decode(Item.self, from: data2)
        
        item1.syncState?.updatedFields.append("starred")
        
        XCTAssertEqual(item1.safeMerge(item2), false)
    }
    
    func testAccess(){
        let data1 = Data("""
            {
                "memriID": "0x012345",
                "starred": true,
                "dateCreated": "2020-04-10T11:11:11Z",
                "version": 10
            }
            """.utf8
        )
        let item1: Item = try! MemriJSONDecoder.decode(Item.self, from: data1)
        
        let dt = item1.dateAccessed
        item1.access()
        XCTAssertNotEqual(dt, item1.dateAccessed)
    }
    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
