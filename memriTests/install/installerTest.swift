//
// installerTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class installerTest: XCTestCase {
    override init() {
        super.init()

        DatabaseController.realmTesting = true
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClearDatabase() throws {
        // Delete DB
        let root = try RootContext(name: "", key: "")
        root.installer.clearDatabase(root)

        let item = try Cache.createItem(AuditItem.self, values: ["json": "1"])
        guard let uid = item.uid.value, let _ = getItem("AuditItem", uid) else {
            XCTFail("Could not write to the database")
            return
        }

        root.installer.clearDatabase(root)

        if let _ = getItem("AuditItem", uid) {
            XCTFail("Failed clearing the database")
        }
    }

    func testInstallDefaultDatabase() throws {
        // Delete DB
        let root = try RootContext(name: "", key: "")
        root.installer.clearDatabase(root)

        // Install default db
        root.installer.installDefaultDatabase(root)

        let realm = DatabaseController.getRealm()
        XCTAssertTrue(realm.objects(CVUStoredDefinition.self).count > 20)
    }

    func testInstallDemoDatabase() throws {
        // Delete DB
        let root = try RootContext(name: "", key: "")
        root.installer.clearDatabase(root)

        // Install default db
        root.installer.installDemoDatabase(root)

        let realm = DatabaseController.getRealm()
        XCTAssertTrue(realm.objects(CVUStoredDefinition.self).count > 20)
    }

    func testClearSessions() throws {
        // Delete DB
        let root = try RootContext(name: "", key: "")
        root.installer.clearDatabase(root)

        // Install default db
        root.installer.installDefaultDatabase(root)

        let uid = root.sessions.state?.uid.value

        root.installer.clearSessions(root)

        XCTAssertNotEqual(root.sessions.state?.uid.value, uid)
    }
}
