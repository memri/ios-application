//
//  FileTest.swift
//  memri
//
//  Created by Koen van der Veen on 28/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

class FileTest: XCTestCase {
    
    var testFile: File = File()

    override func setUpWithError() throws {
        // text file containing "test string\n")
        testFile.uri = "testfile.txt"
    }

    func testDecode() throws {
        let data = Data(
            """
            {
              "uri" : "testfile.txt"
            }
            """.utf8
        )
        let file: File = try JSONDecoder().decode(File.self, from: data)
        let fileContent: String? = file.read()
        XCTAssertTrue(fileContent == "test string\n")
    }
    
    func testCache() throws {
        var _: String? = testFile.read()
        let cached: String? = try fileCache.read("testfile.txt")
        XCTAssertTrue(cached == "test string\n")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
