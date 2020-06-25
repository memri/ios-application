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
            }
            """.utf8
        )
        let item: Item = try! JSONDecoder().decode(Item.self, from: data)
    }
    
    func testGetString(){
        let data = Data("""
            {
                "memriID": "0x012345",
            }
            """.utf8
        )
        let item: Item = try! JSONDecoder().decode(Item.self, from: data)
        
        XCTAssertTrue(item.getString("memriID") == "0x012345") 
    }

    func testExample() throws {
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
