//
//  ExpressionTests.swift
//  memriTests
//
//  Created by Ruben Daniels on 7/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class ExpressionTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExecute() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        let item = try Cache.createItem(Note.self, values: [ "title": "hello"])
        let expr = Expression(".title", startInStringMode: false,
                              lookup: context.views.lookupValueOfVariables,
                              execFunc: context.views.executeFunction)
        let args = ViewArguments(nil, item)
        XCTAssertEqual(try expr.execute(args) as? String, "hello")
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
