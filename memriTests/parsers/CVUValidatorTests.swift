//
//  CVUValidatorTests.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class CVUValidatorTests: XCTestCase {
	override func setUpWithError() throws {}

	override func tearDownWithError() throws {}

	private func parse(_ snippet: String) throws -> [CVUParsedDefinition] {
		let lexer = CVULexer(input: snippet)
		let tokens = try lexer.tokenize()
		let parser = CVUParser(tokens, try RootContext(name: "", key: "").mockBoot(),
							   lookup: { _, _ in }, execFunc: { _, _, _ in })
		let x = try parser.parse()
		return x
	}

	private func toCVUString(_ list: [CVUParsedDefinition]) -> String {
		list.map { $0.toCVUString(0, "    ") }.joined(separator: "\n\n")
	}

	func testColorDefinition() throws {
		let snippet = """
		[color = "background"] {
		    dark: #ff0000
		    light: #330000
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testStyleDefinition() throws {
		let snippet = """
		[style = "my-label-text"] {
		    color: highlight
		    border: background 1
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testRendererDefinition() throws {
		let snippet = """
		[renderer = "generalEditor"] {
		    sequence: labels starred other dates
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testLanguageDefinition() throws {
		let snippet = """
		[language = "Dutch"] {
		    addtolist: "Voeg toe aan lijst..."
		    sharewith: "Deel met..."
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testNamedViewDefinition() throws {
		let snippet = """
		.defaultButtonsForItem {
		    editActionButton: toggleEditMode
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testTypeViewDefinition() throws {
		let snippet = """
		Person {
		    title: "{.firstName}"
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testListViewDefinition() throws {
		let snippet = """
		Person[] {
		    title: "All People"
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
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

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		XCTAssertEqual(validator.validate(parsed), true)
	}

	func testUIElementProperties() throws {
		let snippet = """
		[renderer = "list"] {
		    VStack {
		        alignment: lkjlkj
		        font: 14

		        Text {
		            align: top
		            textAlign: center
		            font: 12 light
		        }
		        Text {
		            maxheight: 500
		            cornerRadius: 10
		            border: #ff0000 1
		        }
		    }
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		_ = validator.validate(parsed)

		XCTAssertEqual(validator.errors.count, 1)
		XCTAssertEqual(validator.warnings.count, 1)
	}

	func testActionProperties() throws {
		let snippet = """
		Person {
		    viewArguments: { readonly: true }

		    navigateItems: [
		        openView {
		            title: 10
		            arguments: {
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
		        }
		        openViewByName {
		            title: "{$starred} {type.plural()}"
		            arguments: {
		                name: "filter-starred"
		                include: "all-{type}"
		            }
		        }
		        openViewByName {
		            title: "{$all} {type.lowercased().plural()}"
		            arguments: {
		                name: "all-{type}"
		            }
		        }
		    ]
		}
		"""

		let parsed = try parse(snippet)
		let validator = CVUValidator()
		_ = validator.validate(parsed)

		validator.debug()

		XCTAssertEqual(validator.errors.count, 1)
		XCTAssertEqual(validator.warnings.count, 0)
	}

	func testLargeCVU() throws {
		let fileURL = Bundle.main.url(forResource: "example", withExtension: "view")
		let code = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)

		let viewDef = CVU(code, try RootContext(name: "", key: "").mockBoot(),
						  lookup: { _, _ in 10 },
						  execFunc: { _, _, _ in 20 })

		let parsed = try viewDef.parse()

		let validator = CVUValidator()
		_ = validator.validate(parsed)

		validator.debug()

		XCTAssertEqual(validator.errors.count, 0)
		XCTAssertEqual(validator.warnings.count, 1)
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
