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
    
    func getExpr(_ context:RootContext, _ code:String) -> Expression {
        return Expression(code,
            startInStringMode: false,
            lookup: context.views.lookupValueOfVariables,
            execFunc: context.views.executeFunction)
    }
    
    func testActionAddItem() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        try context.sessions.load(context)
        
        let name = UUID().uuidString
        let item = try Cache.createItem(Indexer.self, values: [ "name": name])
        let values:[String:[String:Any?]] = [
            "template": [
                "targetDataType": "Address",
                "name": getExpr(context, ".name"),
                "indexer": getExpr(context, "."),
                "_type": "IndexerRun"
            ]
        ]
        let action = ActionAddItem(context, values: values)
        
        context.executeAction(action, with: item)
        
        let realm = DatabaseController.getRealm()
        let indexerRun = realm.objects(IndexerRun.self).filter("name = '\(name)'").first
        XCTAssertNotNil(indexerRun)
        XCTAssertNotNil(indexerRun?.indexer)
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
