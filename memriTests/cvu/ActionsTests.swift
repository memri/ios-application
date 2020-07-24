//
//  ActionsTests.swift
//  memriTests
//
//  Created by Ruben Daniels on 7/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class ActionsTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testActionOpenSession() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        try context.sessions.load(context)
        
        let sessionState = try Cache.createItem(CVUStateDefinition.self, values: [
            "definition": """
            [session] {
                [view] {
                    [datasource = pod] {
                        query: "Photo"
                    }
                }
            }
            """
        ])
        let session = try Session(sessionState, context.sessions)
        
        try ActionOpenSession.exec(context, ["session": session])
        
        XCTAssertEqual(context.currentView?.datasource.query, "Photo")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
