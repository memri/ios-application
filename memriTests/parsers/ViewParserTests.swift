//
//  ViewParserTests.swift
//
//  Created by Ruben Daniels on 5/20/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import XCTest
@testable import memri

class ViewParserTests: XCTestCase {
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
    }
    
    private func parse(_ snippet:String) throws -> [ParsedDefinition] {
        let lexer = ViewLexer(input: snippet)
        let tokens = try lexer.tokenize()
        let parser = ViewParser(tokens, lookup: {_,_ in}, execFunc: {_,_,_ in})
        let x = try parser.parse()
        return x
    }
    
    func testColorDefinition() throws {
        let snippet = """
        [color = "background"] {
            light: #330000
            dark: #ff0000
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[[color = "background"] { [dark: #FF0000FF;light: #330000FF] }]"#)
    }
    
    func testStyleDefinition() throws {
        let snippet = """
        [style = "my-label-text"] {
            border: background 1
            color: highlight
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[[style = "my-label-text"] { [border: ["background", 1.0];color: "highlight"] }]"#)
    }
    
    func testRendererDefinition() throws {
        let snippet = """
        [renderer = "generalEditor"] {
            sequence: labels starred other dates
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[[renderer = "generalEditor"] { [sequence: ["labels", "starred", "other", "dates"]] }]"#)
    }
    
    func testLanguageDefinition() throws {
        let snippet = """
        [language = "Dutch"] {
            sharewith: "Deel met..."
            addtolist: "Voeg toe aan lijst..."
        }
        """
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[[language = "Dutch"]  [addtolist: "Voeg toe aan lijst...";sharewith: "Deel met..."] }]"#)
    }
    
    func testNamedViewDefinition() throws {
        let snippet = """
        .defaultButtonsForDataItem {
            editActionButton: toggleEditMode
        }
        """
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[.defaultButtonsForDataItem { [editActionButton: ActionDescription(actionName: toggleEditMode)] }]"#)
    }
    
    func testTypeViewDefinition() throws {
        let snippet = """
        Person {
            title: "{.firstName}"
        }
        """
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[Person { [title: Expression({.firstName}, startInStringMode:true)] }]"#)
    }
    
    func testListViewDefinition() throws {
        let snippet = """
        Person[] {
            title: "All People"
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person[] { [title: "All People"] }]"#)
    }
    
    func testMultipleDefinitions() throws {
        let snippet = """
        [color = "background"] {
            light: #330000
            dark: #ff0000
        }
        [style = "my-label-text"] {
            border: background 1
            color: highlight
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[[color = "background"] { [dark: #FF0000FF;light: #330000FF] }, [style = "my-label-text"] { [border: ["background", 1.0];color: "highlight"] }]"#)
    }
    
    // TODO
//    func testTypeQueryViewDefinition() throws {
//        let snippet = """
//        Person[ANY address.country = "USA"] {
//            title: "All People"
//        }
//        """
//
//        let results = try parse(snippet)
//        print(results.description)
//
//        XCTAssertEqual(results.description, #"[View("", type:Person[], query:nil context:[title: All People]]"#)
//    }
    
    func testNestedObjects() throws {
        let snippet = """
        Person {
            group {
                key: value
            }
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [group: ["key": "value"]] }]"#)
    }
    
    func testNestedObjectsUsingColon() throws {
        let snippet = """
        Person: {
            group: {
                key: value
            }
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [group: ["key": "value"]] }]"#)
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
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [group: ["key": "value"];key: 10.0] }]"#)
    }
    
    func testArrayStringProperty() throws {
        let snippet = """
        Person {
            sequence: labels starred other dates
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [sequence: ["labels", "starred", "other", "dates"]] }]"#)
    }
    
    func testArrayMixedProperty() throws {
        let snippet = """
        Person {
            sequence: labels 5 "other" test {date: 10}
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [sequence: ["labels", 5.0, "other", "test", ["date": 10.0]]] }]"#)
    }
    
    func testArrayMultilineProperty() throws {
        let snippet = """
        Person {
            sequence: [
                showSharePanel { title: "{$sharewith}" }
                addToPanel { title: "{$addtolist}" }
                duplicate { title: "{$duplicate} {type}" }
            ]

            key: value
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [key: "value";sequence: [ActionDescription(actionName: showSharePanel), ActionDescription(actionName: addToPanel), ActionDescription(actionName: duplicate)]] }]"#)
    }
    
    func testNestedRendererDefinition() throws {
        let snippet = """
        Person {
            [renderer = "timeline"] {
                timeProperty: dateCreated
            }
        }
        """
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[Person { [renderDefinitions: [[renderer = "timeline"] { [timeProperty: "dateCreated"] }]] }]"#)
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
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [key: 10.0;renderDefinitions: [[renderer = "timeline"] { [timeProperty: "dateCreated"] }]] }]"#)
    }
    
    func testStringExpressionProperty() throws {
        let snippet = """
        Person {
            title: "{.firstName}"
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: Expression({.firstName}, startInStringMode:true)] }]"#)
    }
    
    func testExpressionProperty() throws {
        let snippet = """
        Person {
            title: {{.firstName}}
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: Expression(.firstName, startInStringMode:false)] }]"#)
    }
    
    func testStringProperty() throws {
        let snippet = """
        Person { title: "hello" }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: "hello"] }]"#)
    }
    
    func testMultilineStringProperty() throws {
        let snippet = """
        Person { title: "hello
                         world!" }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, """
        [Person { [title: "hello
                         world!"] }]
        """)
    }
    
    func testNumberProperty() throws {
        let snippet = """
        Person { title: -5.34 }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: -5.34] }]"#)
    }
    
    func testBoolProperty() throws {
        let snippet = """
        Person { title: true }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: true] }]"#)
    }
    
    func testNilProperty() throws {
        let snippet = """
        Person { title: nil }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [title: nil] }]"#)
    }
    
    func testIdentifierProperty() throws {
        let snippet = """
        Person { defaultRenderer: thumbnail.grid }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [defaultRenderer: "thumbnail.grid"] }]"#)
    }
    
    func testColorProperty() throws {
        let snippet = """
        Person { color: #f0f }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [color: #FF00FFFF] }]"#)
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
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [array: ["10", 5.0];bool: false;number: 10.0;object: ["test": 10.0];string: "test"] }]"#)
    }
    
    func testSingleLineJSONSyntax() throws {
        let snippet = """
        "Person": { "string": "test", "array": ["10", 5], "object": { "test": 10 }, "bool": false, "number": 10, }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [array: ["10", 5.0];bool: false;number: 10.0;object: ["test": 10.0];string: "test"] }]"#)
    }
    
    func testCSSLikeSyntax() throws {
        let snippet = """
        Person {
            background: #fff;
            border: 1 red;
            padding: 1 2 3 4;
        }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [background: #FFFFFFFF;border: [1.0, "red"];padding: [1.0, 2.0, 3.0, 4.0]] }]"#)
    }
    
    func testSingleLineCSSLikeSyntax() throws {
        let snippet = """
        Person { background: #fff; border: 1 red; padding: 1 2 3 4; }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [background: #FFFFFFFF;border: [1.0, "red"];padding: [1.0, 2.0, 3.0, 4.0]] }]"#)
    }
    
    func testSingleLineSyntax() throws {
        let snippet = """
        Person { background: #fff, border: 1 red, padding: 1 2 3 4, object: { test: 1 } }
        """
        
        let results = try parse(snippet)
        
        XCTAssertEqual(results.description, #"[Person { [background: #FFFFFFFF;border: [1.0, "red"];object: ["test": 1.0];padding: [1.0, 2.0, 3.0, 4.0]] }]"#)
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
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[Person { [background: #FFFFFFFF;bla: ["test": 1.0];object: ["test": 1.0]] }]"#)
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
        
        let results = try parse(snippet)
        print(results)
        
        XCTAssertEqual(results.description, #"[Person { [children: [VStack { alignment: HorizontalAlignment(key: SwiftUI.AlignmentKey(bits: 140735394557288)), font: 14.0 , Text { font: [12.0, SwiftUI.Font.Weight(value: -0.4)], frame: [nil, nil, nil, nil, Optional(SwiftUI.Alignment(horizontal: SwiftUI.HorizontalAlignment(key: SwiftUI.AlignmentKey(bits: 140735394557312)), vertical: SwiftUI.VerticalAlignment(key: SwiftUI.AlignmentKey(bits: 140735394557361))))], textalign: center }, Text { cornerborder: [#FF0000FF, 1.0, 10.0], cornerradius: 10.0, frame: [nil, nil, nil, Optional(500.0), nil] }}]] }]"#)
    }
    
    func testSerialization() throws {
        let fileURL = Bundle.main.url(forResource: "example", withExtension: "view")
        let code = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)

        let viewDef = ViewDefinitionParser(code,
            lookup: { lookup, viewArgs in return 10 },
            execFunc: { lookup, args, viewArgs in return 20 })
        
        let results = try viewDef.parse()
        
        let codeClone = results.map{$0.toString(0, "    ")}.joined(separator: "\n")
        print(codeClone)
        
        let viewDefClone = ViewDefinitionParser(codeClone,
            lookup: { lookup, viewArgs in return 10 },
            execFunc: { lookup, args, viewArgs in return 20 })
        
        let codeCloneClone = try viewDefClone.parse().map{$0.toString(0, "    ")}.joined(separator: "\n")
        
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
        catch let ViewParseErrors.UnexpectedToken(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.EOF)")
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
        catch let ViewParseErrors.ExpectedCharacter(chr, token) {
            XCTAssertEqual(chr, "]")
            XCTAssertEqual("\(token)", "\(ViewToken.CurlyBracketOpen(0, 16))")
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
        catch let ViewParseErrors.MissingExpressionClose(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.EOF)")
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
        catch let ViewParseErrors.MissingExpressionClose(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.EOF)")
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
        catch let ViewParseErrors.ExpectedIdentifier(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.BracketClose(1, 21))")
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
        catch let ViewParseErrors.ExpectedIdentifier(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.Number(5, 0, 2))")
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
        catch let ViewParseErrors.UnexpectedToken(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.BracketClose(1, 21))")
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
        catch let ViewParseErrors.ExpectedKey(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.Colon(1, 20))")
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
            print(try parse(snippet))
            _ = try parse(snippet)
        }
        catch let ViewParseErrors.ExpectedKey(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.Colon(1, 17))")
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
        catch let ViewParseErrors.MissingQuoteClose(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.EOF)")
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
        catch let ViewParseErrors.ExpectedString(token) {
            XCTAssertEqual("\(token)", "\(ViewToken.Identifier("red", 0, 9))")
            return
        }
        
        XCTFail()
    }
    
    
    
    // Test identifier { when its means as a key:object
    

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
