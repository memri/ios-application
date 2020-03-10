//
//  ViewTest.swift
//  memri
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import XCTest
@testable import memri

class ViewTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadSessionViewFromJson() {
        let sessionView =  try! SessionView.from_json("empty_sessionview")
        XCTAssert(sessionView.title == "testtitle")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
