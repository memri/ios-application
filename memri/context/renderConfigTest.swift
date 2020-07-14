//
//  renderConfigTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 08/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
@testable import memri
import XCTest

class RenderConfigTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testLoadListConfig() throws {
		//        var listConfig = try! ListConfig.fromJSONFile("listconfig")
	}

	func testLoadItemComponent() throws {
		var x = try! ItemRenderer(baseComponent: try! ItemRendererComponent.fromJSONFile("list_item_component"))
		//        var x = try! ItemRenderer.fromJSONFile("list_item_component")
		//        var listConfig = try! ViewComponent.fromJSONFile("listconfig")
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
