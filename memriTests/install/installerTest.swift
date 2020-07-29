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
        let didFinish = self.expectation(description: #function)
        
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }
            
            // Delete DB
            self.installer.clearDatabase(context) { error in
                XCTAssertNil(error)
                
                do {
                    let item = try Cache.createItem(AuditItem.self, values: ["json": "1"])
                
                    guard let uid = item.uid.value, let _ = getItem("AuditItem", uid) else {
                        XCTFail("Could not write to the database")
                        return
                    }

                    self.installer.clearDatabase(context) { error in
                        XCTAssertNil(error)

                        if let _ = getItem("AuditItem", uid) {
                            XCTFail("Failed clearing the database")
                        }
                        
                        didFinish.fulfill()
                    }
                }
                catch { XCTFail("\(error)") }
            }
        }
        
        // 3. Wait until the expectation is fulfilled
        wait(for: [didFinish], timeout: 20)
    }

    func testInstallDefaultDatabase() throws {
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }
        
            // Delete DB
            self.installer.clearDatabase(context) { error in
                XCTAssertNil(error)
                
                // Install default db
                self.installer.installDefaultDatabase(context) { error in
                    XCTAssertNil(error)
                    
                    self.installer.ready(context)

                    DatabaseController.current {
                        XCTAssertTrue($0.objects(CVUStoredDefinition.self).count > 20)
                    }
                }
            }
        }
    }

    func testInstallDemoDatabase() throws {
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }
            
            // Delete DB
            self.installer.clearDatabase(context) { error in
                XCTAssertNil(error)

                // Install default db
                self.installer.installDemoDatabase(context) { error in
                    XCTAssertNil(error)
                    
                    self.installer.ready(context)

                    DatabaseController.current {
                        XCTAssertTrue($0.objects(CVUStoredDefinition.self).count > 20)
                    }
                }
            }
        }
    }

    func testClearSessions() throws {
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }
            
            // Delete DB
            self.installer.clearDatabase(context) { error in
                XCTAssertNil(error)

                // Install default db
                self.installer.installDefaultDatabase(context) { error in
                    XCTAssertNil(error)
                    
                    self.installer.ready(context)

                    let uid = context.sessions.state?.uid.value

                    self.installer.clearSessions(context) { error in
                        XCTAssertNil(error)
                        XCTAssertNotEqual(context.sessions.state?.uid.value, uid)
                    }
                }
            }
        }
    }
}
