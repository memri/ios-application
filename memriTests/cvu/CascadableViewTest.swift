//
// CascadableViewTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class CascadableViewTest: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCascadeInheritNamedWithViewArguments() throws {
        installer.installForTesting(boot: true) { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }

            try context.sessions.load(context)

            let view = try Cache.createItem(CVUStateDefinition.self, values: [
                "definition": """
                [view] {
                    defaultRenderer: "photoViewer"
                    inherit: "all-photos"
                }
                """,
            ])
            let realm = try DatabaseController.getRealmSync()
            guard let photo = realm.objects(Photo.self).last else {
                throw "No photos loaded in the database"
            }
            let args = ViewArguments([
                "currentItem": Expression("item(\(photo.genericType), \(photo.uid.value ?? -1))"),
            ])

            try context.currentSession?.setCurrentView(view, args)

            guard let parsedArgs = context.currentView?
                .head["viewArguments"] as? CVUParsedDefinition
            else {
                throw "ViewArguments is not set"
            }

            XCTAssertNotNil(parsedArgs["currentItem"])
            XCTAssertEqual(context.currentView?.datasource.query, "Photo")
            XCTAssertEqual(context.currentView?.activeRenderer, "photoViewer")
        }
    }

    func testCascadeInheritCopiedWithViewArguments() throws {
        installer.installForTesting(boot: true) { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }

            try context.sessions.load(context)

            var view = try Cache.createItem(CVUStateDefinition.self, values: [
                "definition": """
                [view] {
                    [datasource = pod] {
                        query: "Photo"
                    }
                }
                """,
            ])

            try context.currentSession?.setCurrentView(view)

            view = try Cache.createItem(CVUStateDefinition.self, values: [
                "definition": """
                [view] {
                    defaultRenderer: "photoViewer"
                    inherit: {{view}}
                }
                """,
            ])
            let realm = try DatabaseController.getRealmSync()
            guard let photo = realm.objects(Photo.self).last else {
                throw "No photos loaded in the database"
            }
            let args = ViewArguments([
                "currentItem": Expression("item(\(photo.genericType), \(photo.uid.value ?? -1))"),
            ])

            try context.currentSession?.setCurrentView(view, args)

            guard let parsedArgs = context.currentView?
                .head["viewArguments"] as? CVUParsedDefinition
            else {
                throw "ViewArguments is not set"
            }

            XCTAssertNotNil(parsedArgs["currentItem"])
            XCTAssertEqual(context.currentView?.datasource.query, "Photo")
            XCTAssertEqual(context.currentView?.activeRenderer, "photoViewer")
        }
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
