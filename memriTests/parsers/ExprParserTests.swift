//
// ExprParserTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class ExprParserTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    private func parse(_ snippet: String) throws -> ExprNode {
        let lexer = ExprLexer(input: snippet)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        return try parser.parse()
    }

    func testArithmeticOperators() throws {
        let snippet = "(5 + 10 * 4 - 3 / 10) / 10"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(Division, lhs: BinaryOpNode(Minus, lhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(10.0), rhs: NumberNode(4.0))), rhs: BinaryOpNode(Division, lhs: NumberNode(3.0), rhs: NumberNode(10.0))), rhs: NumberNode(10.0))"
        )
    }

    func testAnd() throws {
        let snippet = "true and false"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionAND, lhs: BoolNode(true), rhs: BoolNode(false))"
        )
    }

    func testOr() throws {
        let snippet = "true or false"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionOR, lhs: BoolNode(true), rhs: BoolNode(false))"
        )
    }

    func testSimpleCondition() throws {
        let snippet = "true ? 'yes' : 'no'"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "ConditionNode(condition: BoolNode(true), trueExp: StringNode(yes), falseExp: StringNode(no))"
        )
    }

    func testMultiCondition() throws {
        let snippet = "true ? false and true ? -1 : false or true ? 'yes' : 'no' : -1"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "ConditionNode(condition: BoolNode(true), trueExp: ConditionNode(condition: BinaryOpNode(ConditionAND, lhs: BoolNode(false), rhs: BoolNode(true)), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: ConditionNode(condition: BinaryOpNode(ConditionOR, lhs: BoolNode(false), rhs: BoolNode(true)), trueExp: StringNode(yes), falseExp: StringNode(no))), falseExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)))"
        )
    }

    func testConditionEquals() throws {
        let snippet = "true = false"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionEquals, lhs: BoolNode(true), rhs: BoolNode(false))"
        )
    }

    func testConditionNotEquals() throws {
        let snippet = "true != false"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionNotEquals, lhs: BoolNode(true), rhs: BoolNode(false))"
        )
    }

    func testConditionGreaterThan() throws {
        let snippet = "5 > 10"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionGreaterThan, lhs: NumberNode(5.0), rhs: NumberNode(10.0))"
        )
    }

    func testConditionGreaterThanOrEqual() throws {
        let snippet = "5 >= 10"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionGreaterThanOrEqual, lhs: NumberNode(5.0), rhs: NumberNode(10.0))"
        )
    }

    func testConditionLessThan() throws {
        let snippet = "5 < 10"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionLessThan, lhs: NumberNode(5.0), rhs: NumberNode(10.0))"
        )
    }

    func testConditionLessThanOrEqual() throws {
        let snippet = "5 <= 10"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionLessThanOrEqual, lhs: NumberNode(5.0), rhs: NumberNode(10.0))"
        )
    }

    func testLookup() throws {
        let snippet = ".bar and bar.foo(10) and bar[foo = 10] or shouldNeverGetHere"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(ConditionAND, lhs: BinaryOpNode(ConditionAND, lhs: LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(bar, type:propertyOrItem, list:single)]), rhs: CallNode(lookup: LookupNode([VariableNode(bar, type:propertyOrItem, list:single), VariableNode(foo, type:propertyOrItem, list:single)]), argument: [NumberNode(10.0)])), rhs: BinaryOpNode(ConditionOR, lhs: LookupNode([VariableNode(bar, type:propertyOrItem, list:list), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(foo, type:propertyOrItem, list:single)]), rhs: NumberNode(10.0))])]), rhs: LookupNode([VariableNode(shouldNeverGetHere, type:propertyOrItem, list:single)])))"
        )
    }

    func testDotLookup() throws {
        let snippet = "."

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single)])"
        )
    }

    func testMinusPlusModifier() throws {
        let snippet = "-5 + -(5+10) - +'5'"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(Minus, lhs: BinaryOpNode(Plus, lhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(5.0)), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: NumberNode(10.0)))), rhs: NumberExpressionNode(StringNode(5)))"
        )
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

        XCTAssertEqual(
            result.description,
            "BinaryOpNode(Plus, lhs: BinaryOpNode(Plus, lhs: NumberNode(5.0), rhs: StringNode(10.34)), rhs: BoolNode(true))"
        )
    }

    func testTypeConversionToBool() throws {
        let snippet = "0 ? -1 : 1 ? '' ? -1 : 'yes' : -1"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "ConditionNode(condition: NumberNode(0.0), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: ConditionNode(condition: NumberNode(1.0), trueExp: ConditionNode(condition: StringNode(), trueExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0)), falseExp: StringNode(yes)), falseExp: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(1.0))))"
        )
    }

    func testSelfUsageInSubExpression() throws {
        let snippet = ".relation[. = me].firstName"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(relation, type:propertyOrItem, list:list), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single)]), rhs: LookupNode([VariableNode(me, type:propertyOrItem, list:single)]))]), VariableNode(firstName, type:propertyOrItem, list:single)])"
        )
    }

    func testLookupItems() throws {
        let snippet = ".sibling[]"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(sibling, type:propertyOrItem, list:list)])"
        )
    }

    func testLookupReverseEdgeItems() throws {
        let snippet = ".~sibling"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(sibling, type:reverseEdgeItem, list:single)])"
        )
    }

    func testLookupEdges() throws {
        let snippet = "._sibling"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(sibling, type:edge, list:single)])"
        )
    }

    func testLookupReverseEdges() throws {
        let snippet = "._~sibling[]"

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(sibling, type:reverseEdge, list:list)])"
        )
    }

    func testStringModeStartWithString() throws {
        let snippet = "Hello {fetchName()}!"

        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()

        XCTAssertEqual(
            result.description,
            "StringModeNode(expressions: [StringNode(Hello ), CallNode(lookup: LookupNode([VariableNode(fetchName, type:propertyOrItem, list:single)]), argument: []), StringNode(!)])"
        )
    }

    func testStringModeMultipleBlocks() throws {
        let snippet = "Hello {.firstName} {.lastName}"

        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()

        print(result.description)

        XCTAssertEqual(
            result.description,
            "StringModeNode(expressions: [StringNode(Hello ), LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(firstName, type:propertyOrItem, list:single)]), StringNode( ), LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(lastName, type:propertyOrItem, list:single)])])"
        )
    }

    #warning("This does not work, find out why and fix")
    func testStringModeUsingOr() throws {
        let snippet = "{.title or \"test\"} — {.content.plainString}"

        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()

        print(result.description)

        XCTAssertEqual(
            result.description,
            "StringModeNode(expressions: [BinaryOpNode(ConditionOR, lhs: LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(title, type:propertyOrItem, list:single)]), rhs: StringNode(test)), StringNode( — ), LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(content, type:propertyOrItem, list:single), VariableNode(plainString, type:propertyOrItem, list:single)])])"
        )
    }

    func testStringModeStartWithExpression() throws {
        let snippet = "{fetchName()} Hello"

        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()

        print(result.description)

        XCTAssertEqual(
            result.description,
            "StringModeNode(expressions: [CallNode(lookup: LookupNode([VariableNode(fetchName, type:propertyOrItem, list:single)]), argument: []), StringNode( Hello)])"
        )
    }

    func testStringModeWithQuote() throws {
        let snippet = "Photo AND ANY includes.uid = {.uid}"

        let lexer = ExprLexer(input: snippet, startInStringMode: true)
        let tokens = try lexer.tokenize()
        let parser = ExprParser(tokens)
        let result = try parser.parse()
        print(result.description)
        XCTAssertEqual(
            result.description,
            "StringModeNode(expressions: [StringNode(Photo AND ANY includes.uid = ), LookupNode([VariableNode(@@DEFAULT@@, type:propertyOrItem, list:single), VariableNode(uid, type:propertyOrItem, list:single)])])"
        )
    }

    func testExample() throws {
        let snippet = """
        !(test + -5.63537) or 4/3 ? variable.func() : me.address[primary = true].country ? ((4+5 * 10) + test[10]) : 'asdads\\'asdad' + ''
        """

        let result = try parse(snippet)

        XCTAssertEqual(
            result.description,
            "ConditionNode(condition: BinaryOpNode(ConditionOR, lhs: NegationNode(BinaryOpNode(Plus, lhs: LookupNode([VariableNode(test, type:propertyOrItem, list:single)]), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(-1.0), rhs: NumberNode(5.63537)))), rhs: BinaryOpNode(Division, lhs: NumberNode(4.0), rhs: NumberNode(3.0))), trueExp: CallNode(lookup: LookupNode([VariableNode(variable, type:propertyOrItem, list:single), VariableNode(func, type:propertyOrItem, list:single)]), argument: []), falseExp: ConditionNode(condition: LookupNode([VariableNode(me, type:propertyOrItem, list:single), VariableNode(address, type:propertyOrItem, list:list), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(primary, type:propertyOrItem, list:single)]), rhs: BoolNode(true))]), VariableNode(country, type:propertyOrItem, list:single)]), trueExp: BinaryOpNode(Plus, lhs: BinaryOpNode(Plus, lhs: NumberNode(4.0), rhs: BinaryOpNode(Multiplication, lhs: NumberNode(5.0), rhs: NumberNode(10.0))), rhs: LookupNode([VariableNode(test, type:propertyOrItem, list:list), LookupNode([NumberNode(10.0)])])), falseExp: BinaryOpNode(Plus, lhs: StringNode(asdads'asdad), rhs: StringNode())))"
        )
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
