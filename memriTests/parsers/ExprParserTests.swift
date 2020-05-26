//
//  ParserTests.swift
//
//  Created by Ruben Daniels on 5/15/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import XCTest
@testable import memri

class ExprParserTests: XCTestCase {
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
    
    func testArithmeticOperators() throws {
        let snippet = "(5 + 10 * 4 - 3 / 10) / 10"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(Division, lhs: BinaryOpNode(Minus, lhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(10.0), rhs: NumberNode(4.0))), rhs: BinaryOpNode(Division, lhs: NumberNode(3.0), rhs: NumberNode(10.0))), rhs: NumberNode(10.0))")
    }
    
    func testAnd() throws {
        let snippet = "true and false"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(ConditionAND, lhs: BoolNode(true), rhs: BoolNode(false))")
    }
    
    func testOr() throws {
        let snippet = "true or false"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(ConditionOR, lhs: BoolNode(true), rhs: BoolNode(false))")
    }
    
    func testSimpleCondition() throws {
        let snippet = "true ? 'yes' : 'no'"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "ConditionNode(condition: BoolNode(true), trueExp: StringNode(yes), falseExp: StringNode(no))")
    }
    
    func testMultiCondition() throws {
        let snippet = "true ? false and true ? -1 : false or true ? 'yes' : 'no' : -1"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "ConditionNode(condition: BoolNode(true), trueExp: ConditionNode(condition: BinaryOpNode(ConditionAND, lhs: BoolNode(false), rhs: BoolNode(true)), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: ConditionNode(condition: BinaryOpNode(ConditionOR, lhs: BoolNode(false), rhs: BoolNode(true)), trueExp: StringNode(yes), falseExp: StringNode(no))), falseExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)))")
    }
    
    func testLookup() throws {
        let snippet = ".bar and bar.foo(10) and bar[foo = 10] or shouldNeverGetHere"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(ConditionAND, lhs: BinaryOpNode(ConditionAND, lhs: LookupNode([VariableNode(__DEFAULT__), VariableNode(bar)]), rhs: CallNode(lookup: LookupNode([VariableNode(bar), VariableNode(foo)]), argument: [NumberNode(10.0)])), rhs: BinaryOpNode(ConditionOR, lhs: LookupNode([VariableNode(bar), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(foo)]), rhs: NumberNode(10.0))])]), rhs: LookupNode([VariableNode(shouldNeverGetHere)])))")
    }
    
    func testMinusPlusModifier() throws {
        let snippet = "-5 + -(5+10) - +'5'"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(Minus, lhs: BinaryOpNode(Plus, lhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(5.0)), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: NumberNode(10.0)))), rhs: NumberExpressionNode(StringNode(5)))")
    }
    
    func testNegation() throws {
        let snippet = "!true"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "NegationNode(BoolNode(true))")
    }
    
    func testStringEscaping() throws {
        let snippet = "'asdadsasd\\'asdasd'"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "StringNode(asdadsasd'asdasd)")
    }
    
    func testTypeConversionToNumber() throws {
        let snippet = "5 + '10.34' + true"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "BinaryOpNode(Plus, lhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: StringNode(10.34)), rhs: BoolNode(true))")
    }
    
    func testTypeConversionToBool() throws {
        let snippet = "0 ? -1 : 1 ? '' ? -1 : 'yes' : -1"
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "ConditionNode(condition: NumberNode(0.0), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: ConditionNode(condition: NumberNode(1.0), trueExp: ConditionNode(condition: StringNode(), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: StringNode(yes)), falseExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0))))")
    }
    
    func testStringModeStartWithString() throws {
        let snippet = "Hello {fetchName()}!"
        
        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()
        
        XCTAssertEqual(result.description, "StringModeNode(expressions: [StringNode(Hello ), CallNode(lookup: LookupNode([VariableNode(fetchName)]), argument: []), StringNode(!)])")
    }
    
    func testStringModeMultipleBlocks() throws {
        let snippet = "Hello {.firstName} {.lastName}"
        
        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()
        
        XCTAssertEqual(result.description, "StringModeNode(expressions: [StringNode(Hello ), LookupNode([VariableNode(__DEFAULT__), VariableNode(firstName)]), StringNode( ), LookupNode([VariableNode(__DEFAULT__), VariableNode(lastName)])])")
    }
    
    func testStringModeStartWithExpression() throws {
        let snippet = "{fetchName()} Hello"
        
        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()
        
        XCTAssertEqual(result.description, "StringModeNode(expressions: [CallNode(lookup: LookupNode([VariableNode(fetchName)]), argument: []), StringNode( Hello)])")
    }
    
    func testExample() throws {
        let snippet = """
        !(test + -5.63537) or 4/3 ? variable.func() : me.address[primary = true].country ? ((4+5 * 10) + test[10]) : 'asdads\\'asdad' + ''
        """
        
        let result = try parse(snippet)
        
        XCTAssertEqual(result.description, "ConditionNode(condition: BinaryOpNode(ConditionOR, lhs: NegationNode(BinaryOpNode(Plus, lhs: LookupNode([VariableNode(test)]), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(5.63537)))), rhs: BinaryOpNode(Division, lhs: NumberNode(4.0), rhs: NumberNode(3.0))), trueExp: CallNode(lookup: LookupNode([VariableNode(variable), VariableNode(func)]), argument: []), falseExp: ConditionNode(condition: LookupNode([VariableNode(me), VariableNode(address), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(primary)]), rhs: BoolNode(true))]), VariableNode(country)]), trueExp: BinaryOpNode(Plus, lhs: BinaryOpNode(Plus, lhs: NumberNode(4.0), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(5.0), rhs: NumberNode(10.0))), rhs: LookupNode([VariableNode(test), LookupNode([NumberNode(10.0)])])), falseExp: BinaryOpNode(Plus, lhs: StringNode(asdads'asdad), rhs: StringNode())))")
    }
    
    func testErrorIncompleteCondition() throws {
        let snippet = "true ? 'yes'"
        
        do {
            _ = try parse(snippet)
        }
        catch ExprParseErrors.ExpectedConditionElse {
            return
        }
        
        XCTFail()
    }
    
    func testErrorIncompleteBinaryOp() throws {
        let snippet = "5 +"
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.ExpectedExpression(token) {
            XCTAssertEqual("\(token)", "\(ExprToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
    func testErrorUnsupportedBinaryOp() throws {
        let snippet = "5 @ 4"
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.UnexpectedToken(token) {
            if case let ExprToken.Identifier(keyword, _) = token {
                XCTAssertEqual(keyword, "@")
            }
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingParenClose() throws {
        let snippet = "(5 + 10"
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.ExpectedCharacter(chr) {
            XCTAssertEqual(chr, ")")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingCallParenClose() throws {
        let snippet = "foo("
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.ExpectedExpression(token) {
            XCTAssertEqual("\(token)", "\(ExprToken.EOF)")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingBracketClose() throws {
        let snippet = "test[10"
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.ExpectedCharacter(chr) {
            XCTAssertEqual(chr, "]")
            return
        }
        
        XCTFail()
    }
    
    func testErrorMissingQuoteClose() throws {
        let snippet = "'asdads"
        
        do {
            _ = try parse(snippet)
        }
        catch ExprParseErrors.MissingQuoteClose {
            return
        }
        
        XCTFail()
    }
    
    func testErrorUsingCurlyBracesNotInStringMode() throws {
        let snippet = "Hello {fetchName()}"
        
        do {
            _ = try parse(snippet)
        }
        catch let ExprParseErrors.UnexpectedToken(token) {
            XCTAssertEqual("\(token)", "\(ExprToken.CurlyBracketOpen(6))")
            return
        }
        
        XCTFail()
    }
    
    func testErrorUsingCurlyBracesInWrongContext() throws {
        let snippet = "Hello {'{fetchName()}'}"
        
        do {
            let lexer = ExprLexer(input: snippet, startInStringMode: true)
            let tokens = try lexer.tokenize()
            let parser = ExprParser(tokens)
            _ = try parser.parse()
        }
        catch let ExprParseErrors.ExpectedExpression(token) {
            XCTAssertEqual("\(token)", "\(ExprToken.CurlyBracketClose(22))")
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
