//
//  PodAPI.swift
//  memriTests
//
//  Created by Koen van der Veen on 25/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

func wPrint( _ object: @escaping () -> Any){
    let when = DispatchTime.now() + 0.1
    print("hij")

    DispatchQueue.main.asyncAfter(deadline: when) {
        print("def")
        print(object())
    }
}

func wEvalEqual( _ object: @escaping () -> Any,_ other: Any){
    let when = DispatchTime.now() + 0.1

    DispatchQueue.main.asyncAfter(deadline: when) {
        print(object())
    }
}

class PodAPITest: XCTestCase {
    var testPodAPI: PodAPI!

    override func setUp() {
        let key = "mytestkey"
        testPodAPI = PodAPI(key)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testPodInit() {
        XCTAssert(testPodAPI.key == "mytestkey")
    }
    
    // DISABLED due to not having a pod
//    func testPodCreate() {
//        let item = Item()
//        let expectation = self.expectation(description: "create")
//
//        testPodAPI.create(item) { error, uid in
//            XCTAssertNotNil(uid)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 10, handler: nil)
//    }
//
//    func testPodGet() {
//        let item = Note()
//        let expectationCreate = self.expectation(description: "Create2")
//        let expectationGet = self.expectation(description: "Get2")
//
//
//        testPodAPI.create(item) { error, uid in
//            XCTAssertNotNil(uid)
//            XCTAssertNil(error)
//
//            self.testPodAPI.get(item.memriID) { error, dataItem in
//
//                XCTAssertNotNil(dataItem)
//                XCTAssertNil(error)
//
//                expectationGet.fulfill()
//            }
//
//
//            expectationCreate.fulfill()
//        }
//
//
//
//        waitForExpectations(timeout: 10, handler: nil)
//    }
//
    
    func testPodQuery(){
//        let sr = testPodAPI.query("get notes query")
//        XCTAssert(sr.data == [Item.fromUid(uid: "0x01"), Item.fromUid(uid: "0x02")])
    }


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
