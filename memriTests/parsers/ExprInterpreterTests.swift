//
//  InterpreterTests.swift
//
//  Created by Ruben Daniels on 5/15/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import XCTest
@testable import memri

class ExprInterpreterTests: XCTestCase {
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
    }
    
    private func parse(_ snippet:String) throws -> ExprNode {
        let lexer = ExprLexer(input: snippet)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        return try parser.parse()
    }
    
    private func exec(_ snippet:String) throws -> Any? {
        let tree = try parse(snippet)
        let interpreter = ExprInterpreter(tree, {_,_ in}, {_,_,_ in})
        return try interpreter.execute()
    }
    
    func testArithmeticOperators() throws {
        let snippet = "(5 + 10 * 4 - 3 / 10) / 10"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Double, (5 + 10 * 4 - 3 / 10) / 10)
    }
    
    func testAnd() throws {
        let snippet = "true and false"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Bool, false)
    }
    
    func testOr() throws {
        let snippet = "true or false"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Bool, true)
    }
    
    func testSimpleCondition() throws {
        let snippet = "true ? 'yes' : 'no'"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! String, "yes")
    }
    
    func testMultiCondition() throws {
        let snippet = "true ? false and true ? -1 : false or true ? 'yes' : 'no' : -1"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! String, "yes")
    }
    
    func testLookup() throws {
        let snippet = ".bar and bar.foo(10) and bar[foo = 10] or shouldNeverGetHere"
        
        var results = [ExprNode]()
        
        let tree = try parse(snippet)
        let interpreter = ExprInterpreter(tree,
            { lookup, viewArgs in
                results.append(lookup)
                return true
            },
            { lookup, args, viewArgs in
                results.append(lookup)
                XCTAssertEqual(args[0] as! Double, 10)
                return true
            })
        let result = try interpreter.execute()
        
        XCTAssertEqual(results.count, 3)
        
        XCTAssertEqual(results[0].description, "LookupNode([VariableNode(__DEFAULT__), VariableNode(bar)])")
        XCTAssertEqual(results[1].description, "LookupNode([VariableNode(bar), VariableNode(foo)])")
        XCTAssertEqual(results[2].description, "LookupNode([VariableNode(bar), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(foo)]), rhs: NumberNode(10.0))])])")
        
        XCTAssertEqual(result as! Bool, true)
    }
    
    func testMinusPlusModifier() throws {
        let snippet = "-5 + -(5+10) - +'5'"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Double, -25)
    }
    
    func testNegation() throws {
        let snippet = "!true"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Bool, false)
    }
    
    func testStringEscaping() throws {
        let snippet = "'asdadsasd\\'asdasd'"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! String, "asdadsasd'asdasd")
    }
    
    func testTypeConversionToNumber() throws {
        let snippet = "5 + '10.34' + true"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! Double, 16.34)
    }
    
    func testNanStringToInt() throws {
        let snippet = "+'asdasd'"
        
        let result = try exec(snippet)
        
        XCTAssertTrue((result as! Double).isNaN)
    }
    
    func testTypeConversionToBool() throws {
        let snippet = "0 ? -1 : 1 ? '' ? -1 : 'yes' : -1"
        
        let result = try exec(snippet)
        
        XCTAssertEqual(result as! String, "yes")
    }
    
    func testStringModeStartWithString() throws {
        let snippet = "Hello {fetchName()}!"
        
        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let tree = try parser.parse()
        let interpreter = ExprInterpreter(tree,
            { lookup, viewArgs in "" },
            { lookup, args, viewArgs in return "Memri" })
        let result = try interpreter.execute()

        XCTAssertEqual(result as! String, "Hello Memri!")
    }
    
    func testStringModeStartWithExpression() throws {
        let snippet = "{fetchName()} Hello"
        
        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let tree = try parser.parse()
        let interpreter = ExprInterpreter(tree,
            { lookup, viewArgs in "" },
            { lookup, args, viewArgs in return "Memri" })
        let result = try interpreter.execute()

        XCTAssertEqual(result as! String, "Memri Hello")
    }
    
    func testExample() throws {
        let snippet = """
        !(test + -5.63537) or 4/3 ? variable.func() : me.address[primary = true].country ? ((4+5 * 10) + test[10]) : 'asdads\\'asdad' + ''
        """
        
        let tree = try parse(snippet)
        let interpreter = ExprInterpreter(tree,
            { lookup, viewArgs in return 10 },
            { lookup, args, viewArgs in return 20 })
        let result = try interpreter.execute()
        
        XCTAssertEqual(result as! Int, 20)
    }
    
    func testErrorLookupFailure() throws {
        let snippet = ".bar"
        
        let tree = try parse(snippet)
        let interpreter = ExprInterpreter(tree,
            { lookup, viewArgs in throw "Undefined variable" },
            { lookup, args, viewArgs in 1 })
        
        do {
            let _ = try interpreter.execute()
        }
        catch let error {
            XCTAssertEqual(error as! String, "Undefined variable")
            return
        }
        
        XCTFail()
    }
    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
