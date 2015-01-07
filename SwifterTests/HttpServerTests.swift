//
//  HttpServerTests.swift
//  Swifter
//
//  Created by Michail Pishchagin on 07.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import XCTest

class HttpServerTests: XCTestCase {
  private var server: HttpServer!

  override func setUp() {
    super.setUp()
    server = HttpServer()
    let handleRequest: (HttpRequest) -> (HttpResponse) = { request in
      return .InternalServerError
    }
    server["/foo"] = handleRequest
    server["/foo/(.+?)"] = handleRequest
    server["/foo/(.+?)/(.+?)"] = handleRequest
    server["/foo/(.+?)/(.+?)/bar"] = handleRequest
  }

  override func tearDown() {
    server = nil
    super.tearDown()
  }

  func testRouting() {
    XCTAssertEqual(patternForUrl("/foo"), "/foo")
    XCTAssertEqual(patternForUrl("/foo/bar"), "/foo/(.+?)")
    XCTAssertEqual(patternForUrl("/foo/bar/baz"), "/foo/(.+?)/(.+?)")
    XCTAssertEqual(patternForUrl("/foo/bar/baz/bar"), "/foo/(.+?)/(.+?)/bar")
//    XCTAssertEqual(patternForUrl("/foo/пыщ/baz"), "/foo/(.+?)/(.+?)")
//    XCTAssertEqual(patternForUrl("/foo/пыщ/baz/bar"), "/foo/(.+?)/(.+?)/bar")
  }

  func patternForUrl(url: String) -> String {
    let result = server.findHandler(url)
    return result?.0.pattern ?? ""
  }
}
