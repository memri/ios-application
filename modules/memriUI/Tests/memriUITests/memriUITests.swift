import XCTest
@testable import memriUI

final class memriUITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(memriUI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
