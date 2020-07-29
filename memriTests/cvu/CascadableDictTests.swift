//
//  CascadableDictTests.swift
//  memriTests
//
//  Created by Ruben Daniels on 7/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class CascadableDictTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateWithDot() throws {
        installer.installForTesting { error, _ in
            if let error = error { throw "Failed to initialize: \(error)" }
            
            let item = try Cache.createItem(Note.self, values: [ "title": "test"])
            let args = ViewArguments(nil, item)
            XCTAssertEqual(args.get("."), item)
        }
    }
    
    func testCreateFromOtherDictWithDot() throws {
        installer.installForTesting { error, _ in
            if let error = error { throw "Failed to initialize: \(error)" }
            
            let other = ViewArguments(["test": "hello"])
            let item = try Cache.createItem(Note.self, values: [ "title": "test"])
            let args = ViewArguments(other, item)
            XCTAssertEqual(args.get("."), item)
            XCTAssertEqual(args.get("test"), "hello")
        }
    }
    
    func testMergeOtherDict() throws {
        installer.installForTesting { error, _ in
            if let error = error { throw "Failed to initialize: \(error)" }
                
            let other = ViewArguments(["test": "hello"])
            let args = ViewArguments().merge(other)
            XCTAssertEqual(args.get("test"), "hello")
        }
    }
    
    func testMergeOtherDictDotRemains() throws {
        installer.installForTesting { error, _ in
            if let error = error { throw "Failed to initialize: \(error)" }
                
            let other = ViewArguments(["test": "hello"])
            let item = try Cache.createItem(Note.self, values: [ "title": "test"])
            let args = ViewArguments(nil, item).merge(other)
            XCTAssertEqual(args.get("."), item)
            XCTAssertEqual(args.get("test"), "hello")
        }
    }
    
    func testResolveWithDot() throws {
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }
        
            let item = try Cache.createItem(Note.self, values: [ "title": "hello"])
            let expr = Expression(".title",
                startInStringMode: false,
                lookup: context.views.lookupValueOfVariables,
                execFunc: context.views.executeFunction)
            let args = try ViewArguments(["test": expr]).resolve(item)
            
            XCTAssertEqual(args.get("."), item)
            XCTAssertEqual(args.get("test"), "hello")
            XCTAssertEqual(args.head["test"] as? String, "hello")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
