//
//  ViewParserTests.swift
//
//  Created by Ruben Daniels on 5/20/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import XCTest
@testable import memri

class CVUParserTests: XCTestCase {
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
    }
    
    private func parse(_ snippet:String) throws -> [CVUParsedDefinition] {
        let lexer = CVULexer(input: snippet)
        let tokens = try lexer.tokenize()
        let parser = CVUParser(tokens, lookup: {_,_ in}, execFunc: {_,_,_ in})
        let x = try parser.parse()
        return x
    }
    
    private func toCVUString(_ list:[CVUParsedDefinition]) -> String {
        list.map{ $0.toCVUString(0, "    ") }.joined(separator: "\n\n")
    }
    
    private func parseToCVUString(_ snippet:String) throws -> String {
        toCVUString(try parse(snippet))
    }
    
    func testColorDefinition() throws {
        let snippet = """
        [color = "background"] {
            dark: #ff0000
            light: #330000
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testStyleDefinition() throws {
        let snippet = """
        [style = "my-label-text"] {
            color: highlight
            border: background 1
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        [style = "my-label-text"] {
            border: "background" 1
            color: "highlight"
        }
        """)
    }
    
    func testRendererDefinition() throws {
        let snippet = """
        [renderer = "generalEditor"] {
            sequence: labels starred other dates
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        [renderer = "generalEditor"] {
            sequence: "labels" "starred" "other" "dates"
        }
        """)
    }
    
    func testLanguageDefinition() throws {
        let snippet = """
        [language = "Dutch"] {
            addtolist: "Voeg toe aan lijst..."
            sharewith: "Deel met..."
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testNamedViewDefinition() throws {
        let snippet = """
        .defaultButtonsForDataItem {
            editActionButton: toggleEditMode
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testTypeViewDefinition() throws {
        let snippet = """
        Person {
            title: "{.firstName}"
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testListViewDefinition() throws {
        let snippet = """
        Person[] {
            title: "All People"
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testMultipleDefinitions() throws {
        let snippet = """
        [color = "background"] {
            dark: #ff0000
            light: #330000
        }

        [style = "my-label-text"] {
            border: background 1
            color: highlight
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        [color = "background"] {
            dark: #ff0000
            light: #330000
        }

        [style = "my-label-text"] {
            border: "background" 1
            color: "highlight"
        }
        """)
    }
    
    // TODO
//    func testTypeQueryViewDefinition() throws {
//        let snippet = """
//        Person[ANY address.country = "USA"] {
//            title: "All People"
//        }
//        """
//
//        XCTAssertEqual(try parseToCVUString(snippet), snippet)
//        print(results.description)
//
//
//    }
    
    func testNestedObjects() throws {
        let snippet = """
        Person {
            group {
                key: value
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            
            group: {
                key: "value"
            }
        }
        """)
    }
    
    func testNestedObjectsUsingColon() throws {
        let snippet = """
        Person: {
            group: {
                key: value
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            
            group: {
                key: "value"
            }
        }
        """)
    }
    
    func testNestedObjectsWithKeysBefore() throws {
        let snippet = """
        Person {
            key: 10
            group {
                key: value
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: 10
            
            group: {
                key: "value"
            }
        }
        """)
    }
    
    func testEscapedStringProperty() throws {
        let snippet = """
        [language = "Dutch"] {
            sharewith: "Deel \\"met..."
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testMixedQuoteTypeProperty() throws {
        let snippet = """
        [language = "Dutch"] {
            addtolist: "Voeg 'toe' aan lijst..."
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testArrayStringProperty() throws {
        let snippet = """
        Person {
            sequence: labels starred other dates
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            sequence: "labels" "starred" "other" "dates"
        }
        """)
    }
    
    func testArrayMixedProperty() throws {
        let snippet = """
        Person {
            sequence: labels 5 "other" test
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            sequence: "labels" 5 "other" "test"
        }
        """)
    }
    
    func testArrayMultilineProperty() throws {
        let snippet = """
        Person {
            sequence: [
                showOverlay { title: "{$sharewith}" }
                addToPanel { title: "{$addtolist}" }
                duplicate { title: "{$duplicate} {type}" }
            ]

            key: value
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: "value"
            sequence: [
                showOverlay {
                    title: "{$sharewith}"
                }
                addToPanel {
                    title: "{$addtolist}"
                }
                duplicate {
                    title: "{$duplicate} {type}"
                }
            ]
        }
        """)
    }
    
    func testNestedRendererDefinition() throws {
        let snippet = """
        Person {
            [renderer = "timeline"] {
                timeProperty: dateCreated
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            [renderer = "timeline"] {
                timeProperty: "dateCreated"
            }
        }
        """)
    }
    
    func testNestedRendererDefinitionAfterProperty() throws {
        let snippet = """
        Person {
            key: 10
            [renderer = "timeline"] {
                timeProperty: dateCreated
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: 10

            [renderer = "timeline"] {
                timeProperty: "dateCreated"
            }
        }
        """)
    }
    
    func testStringExpressionProperty() throws {
        let snippet = """
        Person {
            title: "{.firstName}"
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testExpressionProperty() throws {
        let snippet = """
        Person {
            title: {{.firstName}}
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }
    
    func testStringProperty() throws {
        let snippet = """
        Person { title: "hello" }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            title: "hello"
        }
        """)
    }
    
    func testMultilineStringProperty() throws {
        let snippet = """
        Person { title: "hello
                         world!" }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            title: "hello
                         world!"
        }
        """)
    }
    
    func testNumberProperty() throws {
        let snippet = """
        Person { title: -5.34 }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            title: -5.34
        }
        """)
    }
    
    func testBoolProperty() throws {
        let snippet = """
        Person { title: true }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            title: true
        }
        """)
    }
    
    func testNilProperty() throws {
        let snippet = """
        Person { title: nil }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            title: null
        }
        """)
    }
    
    func testIdentifierProperty() throws {
        let snippet = """
        Person { defaultRenderer: thumbnail.grid }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            defaultRenderer: "thumbnail.grid"
        }
        """)
    }
    
    func testColorProperty() throws {
        let snippet = """
        Person { color: #f0f }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            color: #ff00ff
        }
        """)
    }
    
    func testJSONCompatibility() throws {
        let snippet = """
        "Person": {
            "string": "test",
            "array": ["10", 5],
            "object": { "test": 10 },
            "bool": false,
            "number": 10,
        }
        """
        // Notice the trailing comma, its there on purpose
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            array: "10" 5
            bool: false
            number: 10
            string: "test"
            
            object: {
                test: 10
            }
        }
        """)
    }
    
    func testSingleLineJSONSyntax() throws {
        let snippet = """
        "Person": { "string": "test", "array": ["10", 5], "object": { "test": 10 }, "bool": false, "number": 10, }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            array: "10" 5
            bool: false
            number: 10
            string: "test"
            
            object: {
                test: 10
            }
        }
        """)
    }
    
    func testCSSLikeSyntax() throws {
        let snippet = """
        Person {
            background: #fff;
            border: 1 red;
            padding: 1 2 3 4;
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            background: #ffffff
            border: 1 "red"
            padding: 1 2 3 4
        }
        """)
    }
    
    func testSingleLineCSSLikeSyntax() throws {
        let snippet = """
        Person { background: #fff; border: 1 red; padding: 1 2 3 4; }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            background: #ffffff
            border: 1 "red"
            padding: 1 2 3 4
        }
        """)
    }
    
    func testSingleLineSyntax() throws {
        let snippet = """
        Person { background: #fff, border: 1 red, padding: 1 2 3 4, object: { test: 1 } }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            background: #ffffff
            border: 1 "red"
            padding: 1 2 3 4
            
            object: {
                test: 1
            }
        }
        """)
    }
    
    func testCurlyBracketsOnSeparateLine() throws {
        let snippet = """
        Person
        {
            background: #fff
            object:
                { test: 1 }
            bla:
            {
                test: 1
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            background: #ffffff
            
            bla: {
                test: 1
            }
            
            object: {
                test: 1
            }
        }
        """)
    }
    
    func testComments() throws {
        let snippet = """
        /* Hello */
        Person {
            /* World */
            key: value
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: "value"
        }
        """)
    }
    
    func testUIElementProperties() throws {
        let snippet = """
        Person {
            VStack {
                alignment: left
                font: 14
                
                Text {
                    align: top
                    textalign: center
                    font: 12 light
                }
                Text {
                    maxheight: 500
                    cornerradius: 10
                    border: #ff0000 1
                }
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            VStack {
                font: 14
                alignment: left

                Text {
                    textalign: center
                    align: top
                    font: 12 light
                }

                Text {
                    maxHeight: 500
                    cornerborder: #ff0000 1 10
                }
            }
        }
        """)
    }
    
    func testUIElementWithoutProperties() throws {
        let snippet = """
        Person {
            VStack {
                alignment: left
                Text { font: 12 light }
                Spacer
                Text { maxheight: 500 }
            }
        }
        """
        
        XCTAssertEqual(try parseToCVUString(snippet), """

        """)
    }
    
    
    func testSerialization() throws {
        let fileURL = Bundle.main.url(forResource: "example", withExtension: "view")
        let code = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)

        let viewDef = CVU(code,
            lookup: { lookup, viewArgs in return 10 },
            execFunc: { lookup, args, viewArgs in return 20 })
        
        let codeClone = toCVUString(try viewDef.parse())
//        print(codeClone) // .prefix(1500))

        let viewDefClone = CVU(codeClone,
            lookup: { lookup, viewArgs in return 10 },
            execFunc: { lookup, args, viewArgs in return 20 })

        let codeCloneClone = toCVUString(try viewDefClone.parse())

        XCTAssertEqual(codeClone, codeCloneClone)
    }
    
    func testErrorMissingCurlBracketClose() throws {
        let snippet = """
        Person {
            test: 1
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.UnexpectedToken(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingBracketCloseInDefinition() throws {
        let snippet = """
        [color = "test" {
            test: 1
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedCharacter(chr, token) {
            XCTAssertEqual(chr, "]")
            XCTAssertEqual("\(token)", "\(CVUToken.CurlyBracketOpen(0, 16))")
            return
        }
        
        XCTFail()
    }
    
//    func testErrorMissingBracketCloseInArray() throws {
//        let snippet = """
//        Person {
//            array: [1, 2
//        }
//        """
//
//        do {
//            _ = try parse(snippet)
//        }
//        catch let ViewParseErrors.UnexpectedToken(token) {
//            XCTAssertEqual("\(token)", "\(ViewToken.CurlyBracketOpen(6, 1))")
//            return
//        }
//
//        XCTFail()
//    }
    
    func testErrorMissingExprCloseBracket() throws {
        let snippet = """
        Person {
            expr: {{.test}
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.MissingExpressionClose(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingExprCloseBrackets() throws {
        let snippet = """
        Person {
            expr: {{.test
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.MissingExpressionClose(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
    func testErrorExtraBracket() throws {
        let snippet = """
        Person {
            expr: [adasd, 5[]
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedIdentifier(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.BracketClose(1, 21))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorTopLevelBracket() throws {
        let snippet = """
        [5,3,4,]
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedIdentifier(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.Number(5, 0, 2))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorExtraCurlyBracket() throws {
        let snippet = """
        Person {
            expr: [adasd, 5{]
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.UnexpectedToken(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.BracketClose(1, 21))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorExtraColonInArray() throws {
        let snippet = """
        Person {
            expr: ["asdads": asdasd]
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedKey(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.Colon(1, 20))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorExtraColonInProperty() throws {
        let snippet = """
        Person {
            expr: asdads: asdasd
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedKey(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.Colon(1, 17))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingQuoteClose() throws {
        let snippet = """
        Person {
            string: "value
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.MissingQuoteClose(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
//    func testErrorMultilineQuote() throws {
//        let snippet = """
//        Person {
//            string: "value
//                     blah"
//        }
//        """
//
//        do {
//            print(try parse(snippet))
//            _ = try parse(snippet)
//        }
//        catch let ViewParseErrors.UnexpectedToken(token) {
//            XCTAssertEqual("\(token)", "\(ViewToken.CurlyBracketOpen(6, 1))")
//            return
//        }
//
//        XCTFail()
//    }
    
    func testErrorIdentifierInDefinition() throws {
        let snippet = """
        [color = red] {
            light: "#ff0000"
        }
        """
        
        do {
            _ = try parse(snippet)
        }
        catch let CVUParseErrors.ExpectedString(token) {
            XCTAssertEqual("\(token)", "\(CVUToken.Identifier("red", 0, 9))")
            return
        }
        
        XCTFail()
    }
    
    /*
     FUTURE TESTS:
     This has the wrong line number (off by one):
     Photo {
         name: "all-photos"
         title: "All Photos"
         defaultRenderer: thumbnail
         queryOptions {
             query: "photo"
             sortProperty: dateModified
             sortAscending: false
         },
         emptyResultText: "There are no photos here yet",
         
         editActionButton: toggleEditMode
         filterButtons: [ showStarred toggleFilterPanel ]
         
         [renderer = thumbnail] {
             itemInset: 1
             edgeInset: 0 0 0 0
             Image, {
                 image: "{.file}" /* ALLOW BOTH STRINGS AND FILES*/
                 resizable: fill
             }
         }
     }
     
     */
    
    // Test identifier { when its means as a key:object
    

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
