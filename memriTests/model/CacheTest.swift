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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCachInit() {
        let podAPI = PodAPI("test")
        let _ = Cache(podAPI)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
