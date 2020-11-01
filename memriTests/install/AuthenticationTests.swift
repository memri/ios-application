//
// AuthenticationTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class AuthenticationTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAuthenticateOwner() throws {
        Authentication.authenticateOwner { error in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }

    func testCreateRootKey() throws {
        let data = try Authentication.createRootKey(areYouSure: true)

        XCTAssertNotNil(data)

        Authentication.getPublicRootKey { _, fetchedData in
            XCTAssertEqual(fetchedData, data)
        }
    }

    func testCreateOwnerAndDBKey() throws {
        installer.installForTesting { error, _ in
            if let error = error {
                XCTFail("\(error)")
                return
            }

            try Authentication.createOwnerAndDBKey()

            Authentication.getOwnerAndDBKey { _, ownerKey, dbKey in
                XCTAssertNotNil(ownerKey)
                XCTAssertNotNil(dbKey)
                XCTAssertEqual(dbKey?.count ?? 0, 64)
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
