//
//  FileTest.swift
//  memri
//
//  Created by Koen van der Veen on 28/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

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
		let fileContent: String? = try file.read()
		XCTAssertTrue(fileContent == "test string\n")
	}

	func testCache() throws {
		var _: String? = try testFile.read()
		let cached: String? = try InMemoryObjectCache.get("testfile.txt") as? String
		XCTAssertTrue(cached == "test string\n")
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
