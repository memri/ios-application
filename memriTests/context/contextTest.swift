//
// contextTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

// TODO: move to integration tests
// class contextTest: XCTestCase {
////    static var doneSetup:Bool = false
////    private let setUp: Void = {
////        guard !contextTest.doneSetup else { return }
////        contextTest.doneSetup = true
////
////        do {
////            let root = try RootContext(name: "")
////            root.installer.clearDatabase(root)
////            root.installer.installDefaultDatabase(root)
////        }
////        catch {
////            print(error)
////        }
////    }()
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testBooting() throws {
//        let root = try RootContext(name: "")
//        root.installer.clearDatabase(root)
//        root.installer.installDefaultDatabase(root)
//        try root.boot()
//
//        XCTAssertEqual(root.currentView?.state?.selector, "[view]")
//    }
//
//    func testSubContext() throws {
//        let root = try RootContext(name: "")
//        root.installer.clearDatabase(root)
//        root.installer.installDefaultDatabase(root)
//        try root.boot()
//        let sub = try root.createSubContext()
//        try sub.currentSession?.setCurrentView(Cache.createItem(CVUStateDefinition.self, values: [
//            "definition": """
//            [view] {
//                [datasource = pod] {
//                    query: "Note"
//                }
//            }
//            """,
//        ]))
//
//        XCTAssertEqual(sub.currentView?.datasource.query, "Note")
//    }
//
//    func testDynamicProperties() throws {
//        let root = try RootContext(name: "")
//        root.installer.clearDatabase(root)
//        root.installer.installDefaultDatabase(root)
//        try root.boot()
//
//        root.showSessionSwitcher = true
//        XCTAssertEqual(root.showSessionSwitcher, true)
//        root.showSessionSwitcher = false
//        XCTAssertEqual(root.showSessionSwitcher, false)
//
//        root.showNavigation = true
//        XCTAssertEqual(root.showNavigation, true)
//        root.showNavigation = false
//        XCTAssertEqual(root.showNavigation, false)
//    }
//
//    //    func testPerformanceExample() throws {
//    //        // This is an example of a performance test case.
//    //        self.measure {
//    //            // Put the code you want to measure the time of here.
//    //        }
//    //    }
// }
