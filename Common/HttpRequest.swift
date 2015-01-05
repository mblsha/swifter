//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct HttpRequest {
    public let url: String
    public let urlParams: [(String, String)] // http://stackoverflow.com/questions/1746507/authoritative-position-of-duplicate-http-get-query-keys
    public let method: String
    public let headers: [String: String]
    public let body: String?
    public var capturedUrlGroups: [String]

    public func params(name: String) -> [String] {
      return reduce(urlParams, []) {
        if $1.0 == name {
          return $0 + [$1.1]
        } else {
          return $0
        }
      }
    }

    public func param(name: String) -> String? {
      return params(name).first
    }
}
