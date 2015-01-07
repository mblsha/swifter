//
//  StringExtensionsTests.swift
//  Swifter
//
//  Created by Michail Pishchagin on 07.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import XCTest

class StringExtensionsTests: XCTestCase {
  func testFullRange() {
    XCTAssertEqual("foo".fullRange.length, 3)
    XCTAssertEqual("пыщ".fullRange.length, 3)
  }

  func testUrlRangeWithoutParams() {
    XCTAssertEqual("foo?bar".urlRangeWithoutParams.length, 3)
    XCTAssertEqual("пыщ?тыщ".urlRangeWithoutParams.length, 3)
  }

  func testCapturedGroups() {
    XCTAssertEqual("foo/bar".capturedGroups(regexp("(.+)/(.+)")), ["foo", "bar"])
    XCTAssertEqual("foo/bar".capturedGroups(regexp("(.+)/(.+)/(.+)")), [])
  }

  func regexp(pattern: String) -> NSRegularExpression {
    return NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(), error: nil)!
  }
}
