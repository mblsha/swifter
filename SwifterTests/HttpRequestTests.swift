//
//  HttpRequestTests.swift
//  Swifter
//
//  Created by Michail Pishchagin on 05.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import XCTest

class HttpRequestTests: XCTestCase {
  func httpRequest(params: [(String,String)]) -> HttpRequest {
    return HttpRequest(url: "", urlGroups: [String:String](), urlParams: params, method: "GET", headers: [String:String](), body: nil)
  }

  func testUrlParams() {
    XCTAssertEqual(httpRequest([("foo", "bar")]).param("foo").value!, "bar")
    XCTAssertFalse(httpRequest([("foo", "bar")]).param("baz").isSuccess)
    XCTAssertEqual(httpRequest([("foo", "bar"), ("foo", "baz")]).param("foo").value!, "bar")
    XCTAssertEqual(httpRequest([("foo", "bar"), ("foo", "baz")]).params("foo"), ["bar", "baz"])
  }
}