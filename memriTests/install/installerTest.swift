//
//  installerTest.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class installerTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testInstaller() throws {
		realmTesting = true

		// Delete DB
		let dbPath = try getRealmPath()
		let fileManager = FileManager()
		try fileManager.removeItem(atPath: dbPath)

		let root = RootContext(name: "", key: "")
		try root.boot()

		XCTAssertEqual(root.realm.objects(AuditItem.self).filter("action = 'install'").first!.action, "install")
	}

	//    func testPerformanceExample() throws {
	//        // This is an example of a performance test case.
	//        self.measure {
	//            // Put the code you want to measure the time of here.
	//        }
	//    }
}
