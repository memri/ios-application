//
//  CVUTests.swift
//  memriTests
//
//  Created by Ruben Daniels on 7/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class CVUTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLineNumbersOfParseErrors() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        let code = """
        /* multi
            line
            comment
        */
        Example[] {
            name: all-locations
            defaultRenderer: list
            filterButtons: showStarred toggleFilterPanel
            
            editActionButton: toggleEditMode
            
            [renderer = list] {
                HStack {
                    Spacer
                    we want to trigger a parse error here
                    Map {
                        location: {{.}}
                        minHeight: 80
                        maxHeight: 80
                    }
                }
            }
        """
        
        do {
            let cvu = CVU(code, context,
                          lookup: context.views.lookupValueOfVariables,
                          execFunc: context.views.executeFunction)
            let _ = try cvu.parse() // TODO: this could be optimized
        }
        catch {
            if let error = error as? CVUParseErrors {
                XCTAssertEqual("\(error.toString(code))", """
                Expected Key and found Identifier('we') instead at line:15 and character:14

                Example[] {
                    name: all-locations
                    defaultRenderer: list
                    filterButtons: showStarred toggleFilterPanel
                    
                    editActionButton: toggleEditMode
                    
                    [renderer = list] {
                        HStack {
                            Spacer
                            we want to trigger a parse error here
                ------------^
                            Map {
                                location: {{.}}
                                minHeight: 80
                                maxHeight: 80
                            }
                        }
                    }
                """)
                
                XCTAssertEqual("\(error)",
                    #"ExpectedKey(memri.CVUToken.Identifier("we", 14, 13))"#)
            }
        }
    }
    
    func testParseErrorOnLastLine() throws {
        guard let context = try installer.installForTesting() else {
            throw "Failed to initialize"
        }
        
        let code = """
        /* multi
            line
            comment
        */
        Example[] {
            trigger parse error
        """
        
        do {
            let cvu = CVU(code, context,
                          lookup: context.views.lookupValueOfVariables,
                          execFunc: context.views.executeFunction)
            let _ = try cvu.parse() // TODO: this could be optimized
        }
        catch {
            if let error = error as? CVUParseErrors {
                XCTAssertEqual("\(error.toString(code))", """
                Expected Key and found Identifier('trigger') instead at line:6 and character:6

                /* multi
                    line
                    comment
                */
                Example[] {
                    trigger parse error
                ----^
                
                """)
                
                XCTAssertEqual("\(error)",
                    #"ExpectedKey(memri.CVUToken.Identifier("trigger", 5, 5))"#)
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
