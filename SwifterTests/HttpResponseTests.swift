//
//  HttpResponseTests.swift
//  Swifter
//
//  Created by Michail Pishchagin on 05.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import XCTest

class HttpResponseTests: XCTestCase {
  func testHttpResponseBodyJson() {
    XCTAssertEqual(HttpResponseBody.JSON(["foo": "bar"]).data()!, "{\"foo\":\"bar\"}")
    XCTAssertEqual(HttpResponseBody.JSON(["foo": "b/a/r"]).data()!, "{\"foo\":\"b/a/r\"}")
  }
}
