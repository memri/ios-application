//
// XCTestManifests.swift
// Copyright © 2020 memri. All rights reserved.

import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(memriUITests.allTests),
        ]
    }
#endif
