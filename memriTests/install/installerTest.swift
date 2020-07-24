//
// installerTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class installerTest: XCTestCase {
    var installer = Installer()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClearDatabase() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        // Delete DB
        installer.clearDatabase(context)

        let item = try Cache.createItem(AuditItem.self, values: ["json": "1"])
        guard let uid = item.uid.value, let _ = getItem("AuditItem", uid) else {
            XCTFail("Could not write to the database")
            return
        }

        installer.clearDatabase(context)

        if let _ = getItem("AuditItem", uid) {
            XCTFail("Failed clearing the database")
        }
    }

    func testInstallDefaultDatabase() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        // Delete DB
        installer.clearDatabase(context)

        // Install default db
        installer.installDefaultDatabase(context)

        let realm = DatabaseController.getRealm()
        XCTAssertTrue(realm.objects(CVUStoredDefinition.self).count > 20)
    }

    func testInstallDemoDatabase() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        // Delete DB
        installer.clearDatabase(context)

        // Install default db
        installer.installDemoDatabase(context)

        let realm = DatabaseController.getRealm()
        XCTAssertTrue(realm.objects(CVUStoredDefinition.self).count > 20)
    }

    func testClearSessions() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        // Delete DB
        installer.clearDatabase(context)

        // Install default db
        installer.installDefaultDatabase(context)

        let uid = context.sessions.state?.uid.value

        installer.clearSessions(context)

        XCTAssertNotEqual(context.sessions.state?.uid.value, uid)
    }
}
