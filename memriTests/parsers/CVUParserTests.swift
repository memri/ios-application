//
// CVUParserTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class CVUParserTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    private func parse(_ snippet: String) throws -> [CVUParsedDefinition] {
        let lexer = CVULexer(input: snippet)
        let tokens = try lexer.tokenize()
        let parser = CVUParser(tokens, try RootContext(name: "").mockBoot(),
                               lookup: { _, _ in }, execFunc: { _, _, _ in })
        let x = try parser.parse()
        return x
    }

    private func toCVUString(_ list: [CVUParsedDefinition]) -> String {
        list.map { $0.toCVUString(0, "    ") }.joined(separator: "\n\n")
    }

    private func parseToCVUString(_ snippet: String) throws -> String {
        toCVUString(try parse(snippet)).replace(#"\n\s+\n"#, "\n\n")
    }

    func testColorDefinition() throws {
        let snippet = """
        [color = background] {
            dark: #ff0000
            light: #330000
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testStyleDefinition() throws {
        let snippet = """
        [style = my-label-text] {
            color: highlight
            border: background 1
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        [style = my-label-text] {
            border: "background" 1
            color: "highlight"
        }
        """)
    }

    func testRendererDefinition() throws {
        let snippet = """
        [renderer = generalEditor] {
            sequence: labels starred other dates
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        [renderer = generalEditor] {
            sequence: "labels" "starred" "other" "dates"
        }
        """)
    }

    func testLanguageDefinition() throws {
        let snippet = """
        [language = Dutch] {
            addtolist: "Voeg toe aan lijst..."
            sharewith: "Deel met..."
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testNamedViewDefinition() throws {
        let snippet = """
        .defaultButtonsForItem {
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
        [color = background] {
            dark: #ff0000
            light: #330000
        }

        [style = my-label-text] {
            border: background 1
            color: highlight
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        [color = background] {
            dark: #ff0000
            light: #330000
        }

        [style = my-label-text] {
            border: "background" 1
            color: "highlight"
        }
        """)
    }

    // TODO:
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
        [language = Dutch] {
            sharewith: "Deel \\"met..."
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testMixedQuoteTypeProperty() throws {
        let snippet = """
        [language = Dutch] {
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
                openViewByName { title: "{$sharewith}" }
                toggleEditMode { title: "{$addtolist}" }
                duplicate { title: "{$duplicate} {type}" }
            ]

            key: value
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: "value"
            sequence: [
                openViewByName {
                    title: "{$sharewith}"
                }
                toggleEditMode {
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
            [renderer = timeline] {
                timeProperty: dateCreated
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            [renderer = timeline] {
                timeProperty: "dateCreated"
            }
        }
        """)
    }

    func testNestedRendererDefinitionAfterProperty() throws {
        let snippet = """
        Person {
            key: 10
            [renderer = timeline] {
                timeProperty: dateCreated
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            key: 10

            [renderer = timeline] {
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
        Person { defaultRenderer: grid }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            defaultRenderer: "grid"
        }
        """)
    }

    func testColorProperty() throws {
        let snippet = """
        Person { color: #f0f }
        """

        XCTAssertEqual(try parseToCVUString(snippet), """
        Person {
            color: #f0f
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
            background: #fff
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
            background: #fff
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
            background: #fff
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
            background: #fff

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

    func testUserState() throws {
        let snippet = """
        Person {
            userState: {
                showStarred: true
            }
        }
        """

        let parsed = try parse(snippet).first

        XCTAssertEqual(toCVUString([parsed!]), snippet)

        guard let _ = parsed!["userState"] as? CVUParsedDefinition else {
            XCTFail()
            throw "Error"
        }
    }

    #warning("Test that this works")
    func testEmptyArray() throws {
        let snippet = """
        Person {
            userState: {
                selection: []
            }
        }
        """

        let parsed = try parse(snippet).first

        XCTAssertEqual(toCVUString([parsed!]), snippet)

        guard let us = parsed!["userState"] as? CVUParsedDefinition,
              us["selection"] is [Any?]
        else {
            XCTFail()
            throw "Error"
        }
    }

    func testViewArguments() throws {
        let snippet = """
        Person {
            viewArguments: {
                readOnly: true
            }
        }
        """

        let parsed = try parse(snippet).first

        XCTAssertEqual(toCVUString([parsed!]), snippet)

        guard let _ = parsed!["viewArguments"] as? CVUParsedDefinition else {
            XCTFail()
            throw "Error"
        }
    }

    func testUIElementProperties() throws {
        let snippet = """
        Person {
            VStack {
                font: 14
                alignment: left

                Text {
                    textAlign: center
                    font: 12 light
                    alignment: top
                }

                Text {
                    maxHeight: 500
                    border: #ff0000 1
                    cornerRadius: 10
                }
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
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
        Person {
            VStack {
                alignment: left

                Text {
                    font: 12 light
                }

                Spacer

                Text {
                    maxheight: 500
                }
            }
        }
        """)
    }

    func testSerialization() throws {
        let fileURL = Bundle.main.url(forResource: "example", withExtension: "view")
        let code = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)

        let viewDef = CVU(code, try RootContext(name: "").mockBoot(),
                          lookup: { _, _ in 10 },
                          execFunc: { _, _, _ in 20 })

        let codeClone = toCVUString(try viewDef.parse())
        //        print(codeClone) // .prefix(1500))

        let viewDefClone = CVU(codeClone, try RootContext(name: "").mockBoot(),
                               lookup: { _, _ in 10 },
                               execFunc: { _, _, _ in 20 })

        let codeCloneClone = toCVUString(try viewDefClone.parse())

        XCTAssertEqual(codeClone, codeCloneClone)
    }

    func testNestedViews() throws {
        let snippet = """
        Person {
            [renderer = generalEditor] {

                picturesOfPerson: {
                    title: "Photos of {.computedTitle()}"

                    SubView {
                        view: {
                            defaultRenderer: "thumbnail.grid"

                            [datasource = pod] {
                                query: "Photo AND ANY includes.uid = {.uid}"
                            }

                            [renderer = thumbnail.grid] {
                                columns: 5
                                itemInset: 0
                            }
                        }
                    }
                }
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testActionStar() throws {
        let snippet = """
        Person {
            [renderer = list] {
                Action {
                    press: star
                }
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testActionAddItem() throws {
        let snippet = """
        Person {
            [renderer = list] {
                press: addItem {
                    template: {
                        name: {{.name}}
                        _type: "ImporterRun"
                    }
                }
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
    }

    func testMultipleActions() throws {
        let snippet = """
        Person {
            [renderer = list] {
                press: [
                    link {
                        dataItem: {{dataItem}}
                        property: {{property}}
                    }
                    closePopup
                ]
            }
        }
        """

        XCTAssertEqual(try parseToCVUString(snippet), snippet)
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

    /*
     FUTURE TESTS:
     This has the wrong line number (off by one):
     Photo {
         name: "all-photos"
         title: "All Photos"
         defaultRenderer: grid
         datasource {
             query: "photo"
             sortProperty: dateModified
             sortAscending: false
         },
         emptyResultText: "There are no photos here yet",

         editActionButton: toggleEditMode
         filterButtons: [ showStarred toggleFilterPanel ]

         [renderer = grid] {
             itemInset: 1
             edgeInset: 0 0 0 0
             Image, {
                 image: "{.file}" /* ALLOW BOTH STRINGS AND FILES*/
                 sizingMode: fill
             }
         }
     }

     This gives a parse error at the [ on line 3
     .defaultSessions {
         currentSessionIndex: 0
         sessionDefinitions: [
             [session] {
                     currentViewIndex: 4
                     viewDefinitions: [
                         [view] {

                                 datasource: {
                                     query: "label"
                                 }
                             }
                         [view] {

                                 datasource: {
                                     query: "person"
                                 }
                             }
                         [view] {

                                 datasource: {
                                     query: "session"
                                 }
                             }
                         [view] {

                                 datasource: {
                                     query: "audititem"
                                 }
                             }
                         [view] {

                                 datasource: {
                                     query: "note"
                                 }
                             }
                     ]
                 }
         ]
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
