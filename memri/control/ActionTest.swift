//
//  actionTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

class actionTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testActionDescription() throws {
        let actionDescription = ActionDescription(actionName: .back)
        XCTAssertTrue(actionDescription.icon == "chevron.left")
    }
    
    func testAction() throws {
        let action: ActionName = .add
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
