//
// ViewsTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class ViewsTest: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCVUValidationErrorsBlockInstallation() throws {
        installer.installForTesting { error, context in
            guard let context = context else { throw "Failed to initialize: \(error!)" }

            let code = """
            Person {
                viewArguments: { readonly: true }

                navigateItems: [
                    openView {
                        title: 10
                        view: {
                            defaultRenderer: timeline

                            datasource {
                                query: "AuditItem appliesTo:{.uid}"
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

            context.views.install(overrideCodeForTesting: code) { error in
                XCTAssertNotNil(error)
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
