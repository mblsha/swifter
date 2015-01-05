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

class HttpParserTests: XCTestCase {
  func testExtractUrlParams() {
    XCTAssertEqual(Params(url: "/rest/auth/1/session"), Params())
    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=bar"), Params([("foo", "bar")]))
    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=bar&foo=bar2"), Params([("foo", "bar"), ("foo", "bar2")]))

    XCTAssertEqual(Params(url: "/rest/auth/1/session?foo=%22b%20ar%22"), Params([("foo", "\"b ar\"")]))
  }
}
