//
// ViewsTest.swift
// Copyright © 2020 memri. All rights reserved.

import XCTest
@testable import memri
    
class ViewsTest: XCTestCase {
    var installer = Installer()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCVUValidationErrorsBlockInstallation() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        let code = """
        Person {
            viewArguments: { readonly: true }

            navigateItems: [
                openView {
                    title: 10
                    view: {
                        defaultRenderer: timeline

                        datasource {
                            query: "AuditItem appliesTo:{.id}"
                            sortProperty: dateCreated
                            sortAscending: true
                        }

                        [renderer = "timeline"] {
                            timeProperty: dateCreated
                        }
                    }
                }
                openViewByName {
                    title: "{$starred} {type.plural()}"
                    viewName: "filter-starred"
                    include: "all-{type}"
                }
                openSessionByName {
                    title: "{$all} {type.lowercased().plural()}"
                    arguments: {
                        sessionName: "all-{type}"
                    }
                }
            ]
        }
        """
        
        XCTAssertThrowsError(try context.views.install(overrideCodeForTesting: code))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
