//
// FileTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class FileTest: XCTestCase {
    var installer = Installer()

    func testWrite() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }
                
            let file = try Cache.createItem(File.self, values: [
                "uri": "testfile.txt"
            ])
            
            try file.write("Hello")
            XCTAssertEqual(try file.read(), "Hello")
        }
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
