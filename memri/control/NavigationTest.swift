//
//  NavigationTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri


class NavigationTest: XCTestCase {



    func testNavigationInit() {
        var navigationItems: [NavigationItem] = try! NavigationItem.fromJSON("navigationItems")

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
