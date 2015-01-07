//
//  HttpServerTests.swift
//  Swifter
//
//  Created by Michail Pishchagin on 07.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import XCTest

func requestHandler(request: HttpRequest) -> (HttpResponse) {
  return .InternalServerError
}

class RouteTests: XCTestCase {
  func testCreateRoute() {
    XCTAssertEqual(route("/foo/:bar").name, "/foo/:bar")
    XCTAssertEqual(route("/foo/:bar").urlGroupNames, ["bar"])
    XCTAssertEqual(route("/foo/:bar").expression.pattern, "/foo/([^/]+)")
  }

  func testUrlGroups() {
    XCTAssertEqual(route("/foo").urlGroups("/foo"), [String: String]())
    XCTAssertEqual(route("/foo/:bar").urlGroups("/foo/val"), ["bar": "val"])
    XCTAssertEqual(route("/foo/:bar/:baz").urlGroups("/foo/val1/val2"), ["bar": "val1", "baz": "val2"])
    XCTAssertEqual(route("/foo/:пыщ1/:пыщ2").urlGroups("/foo/тыц1/тыц2"), ["пыщ1": "тыц1", "пыщ2": "тыц2"])
  }

  func route(name: String) -> HttpServer.Route {
    return HttpServer.Route(name: name, handler: requestHandler)
  }
}

class HttpServerTests: XCTestCase {
  private var server: HttpServer!

  override func setUp() {
    super.setUp()
    server = HttpServer()
    server["/foo"] = requestHandler
    server["/foo/:p1"] = requestHandler
    server["/foo/:p2/:p3"] = requestHandler
    server["/foo/:p4/:p5/bar"] = requestHandler
  }

  override func tearDown() {
    server = nil
    super.tearDown()
  }

  func testRouting() {
    XCTAssertEqual(routeForUrl("/foo"), "/foo")
    XCTAssertEqual(routeForUrl("/foo/bar"), "/foo/:p1")
    XCTAssertEqual(routeForUrl("/foo/bar/baz"), "/foo/:p2/:p3")
    XCTAssertEqual(routeForUrl("/foo/bar/baz/bar"), "/foo/:p4/:p5/bar")
    XCTAssertEqual(routeForUrl("/foo/пыщ/baz"), "/foo/:p2/:p3")
    XCTAssertEqual(routeForUrl("/foo/пыщ/baz/bar"), "/foo/:p4/:p5/bar")
    XCTAssertEqual(routeForUrl("/fooo/bar"), "")

    XCTAssertEqual(routeForUrl("/foo?bar=baz"), "/foo")
    XCTAssertEqual(routeForUrl("/foo/пыщ/baz?bar=baz"), "/foo/:p2/:p3")
}

  func routeForUrl(url: String) -> String {
    let result = server.findRoute(url)
    return result?.name ?? ""
  }
}
