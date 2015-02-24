//
//  SwifterTests.swift
//  SwifterTests
//
//  Created by Michail Pishchagin on 01.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import UIKit
import XCTest

struct Params: Equatable, Printable, DebugPrintable {
  private let urlParams: [(String,String)]

  init() {
    urlParams = []
  }

  init(url: String) {
    urlParams = HttpParser.extractUrlParams(url)
  }

  init(_ params: [(String,String)]) {
    urlParams = params
  }

  var description: String {
    get {
      return debugDescription
    }
  }

  var debugDescription: String {
    get {
      var out: String = ""
      dump(urlParams, &out, name: "urlParams")
      return out
    }
  }
}

func ==(lhs: Params, rhs: Params) -> Bool {
  if lhs.urlParams.count != rhs.urlParams.count {
    dump(lhs.description)
    dump(rhs.description)
    return false
  }

  for i in 0..<lhs.urlParams.count {
    let l: (String,String) = lhs.urlParams[i]
    let r: (String,String) = rhs.urlParams[i]
    if l.0 != r.0 || l.1 != r.1 {
      dump(lhs.description)
      dump(rhs.description)
      return false
    }
  }
  return true
}

// FIXME: rdar://19935413
func swift12sucks(str: String) -> String {
  // dumb Xcode 6.3b2 work-around, where it joins by "\n\r"
  // instead of "\r\n"
  return str.stringByReplacingOccurrencesOfString("\n\r", withString: "\r\n")
}

func httpRequestText(statusLine: String, headerLines: [String], optionalBodyText: String? = nil) -> String {
  let prefix = swift12sucks("\(statusLine) HTTP/1.1\r\n" +
                            join("\r\n", headerLines))
  let bodySeparator = "\r\n\r\n"

  if let bodyText = optionalBodyText {
    let data = bodyText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    return prefix +
           "\r\n" +
           "Content-Length: \(data.length)" +
           bodySeparator +
           bodyText
  } else {
    return prefix +
           bodySeparator
  }
}

func mockReader(requests: [String]) -> MockSocketReader {
  return MockSocketReader(data: swift12sucks(join("", requests)))
}

class HttpParserTests: XCTestCase {
  func testExtractUrlParams() {
    XCTAssertEqual(Params(url: "/rest/auth/1/session"), Params())
    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=bar"), Params([("foo", "bar")]))
    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=bar&foo=bar2"), Params([("foo", "bar"), ("foo", "bar2")]))

    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=%22b%20ar%22"), Params([("foo", "\"b ar\"")]))
  }

  func testHttpRequestTextHelper() {
    XCTAssertEqual(
      httpRequestText("GET /foo", ["Foo: Bar"]),
      "GET /foo HTTP/1.1\r\nFoo: Bar\r\n\r\n")
    XCTAssertEqual(
      httpRequestText("GET /foo", ["Foo: Bar", "Bar: Baz"]),
      "GET /foo HTTP/1.1\r\nFoo: Bar\r\nBar: Baz\r\n\r\n")
    XCTAssertEqual(
      httpRequestText("GET /foo", ["Foo: Bar", "Bar: Baz"], optionalBodyText: "The Data"),
      "GET /foo HTTP/1.1\r\nFoo: Bar\r\nBar: Baz\r\nContent-Length: 8\r\n\r\nThe Data")
  }

  func testUrlRequest() {
    XCTAssertEqual(httpRequests(mockReader([
      httpRequestText("GET /foo1", ["Foo: Bar"]),
      httpRequestText("GET /foo2", ["Foo: Bar"], optionalBodyText: "Data"),
      httpRequestText("GET /foo3", ["Foo: Bar"])
      ])).count, 3)

    XCTAssertEqual(httpRequests(mockReader([
      httpRequestText("GET /foo1/пыщ", ["Пыщ: Тыц"]),
      httpRequestText("GET /foo2/пыщ", ["Пыщ: Тыц"], optionalBodyText: "Бдыщ"),
      httpRequestText("GET /foo3/пыщ", ["Пыщ: Тыц"])
      ])).count, 3)

    let asciiRequest = httpRequests(mockReader([
      httpRequestText("GET /foo2/bar?a=b1&a=b2&v=g",
                      ["Foo: Bar"], optionalBodyText: "Thedata")])).first!
    XCTAssertEqual(asciiRequest.url, "/foo2/bar?a=b1&a=b2&v=g")
    XCTAssertEqual(asciiRequest.param("v").value!, "g")
    XCTAssertEqual(asciiRequest.params("a"), ["b1", "b2"])
    XCTAssertEqual(asciiRequest.method, "GET")
    XCTAssertEqual(asciiRequest.headers["foo"]!, "Bar")
    XCTAssertEqual(asciiRequest.headers["content-length"]!, "7")
    XCTAssertEqual(asciiRequest.bodyUtf8!, "Thedata")

    let utf8Request = httpRequests(mockReader([
      httpRequestText("GET /foo2/пыщ?а=б1&а=б2&в=г",
                      ["Пыщ: Тыц"], optionalBodyText: "Проверка")])).first!
    XCTAssertEqual(utf8Request.url, "/foo2/пыщ?а=б1&а=б2&в=г")
    XCTAssertEqual(utf8Request.param("в").value!, "г")
    XCTAssertEqual(utf8Request.params("а"), ["б1", "б2"])
    XCTAssertEqual(utf8Request.method, "GET")
    XCTAssertEqual(utf8Request.headers["пыщ"]!, "Тыц")
    XCTAssertEqual(utf8Request.headers["content-length"]!, "16")
    XCTAssertEqual(utf8Request.bodyUtf8!, "Проверка")
  }

  func httpRequests(socket: SocketReader) -> [HttpRequest] {
    var result: [HttpRequest] = []
    let parser = HttpParser()
    while let request = parser.nextHttpRequest(socket) {
      result.append(request)
    }
    return result
  }
}
