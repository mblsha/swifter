//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation
import LlamaKit

public struct HttpRequest {
    public let url: String
    private let urlGroups: [String: String]
    public let urlParams: [(String, String)] // http://stackoverflow.com/questions/1746507/authoritative-position-of-duplicate-http-get-query-keys
    public let method: String
    public let headers: [String: String]
    public let body: NSData?

    public var bodyUtf8: String? {
      get {
        if let data = body {
          return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
        }
        return nil
      }
    }

  public init(url: String, urlGroups: [String:String], urlParams: [(String, String)], method: String, headers: [String:String], body: NSData?) {
    self.url = url
    self.urlGroups = urlGroups
    self.urlParams = urlParams
    self.method = method
    self.headers = headers
    self.body = body
  }

    private struct Constants {
      static let HttpRequestDomain = "HttpRequestDomain"

      enum ErrorCode: Int {
        case ParameterNotFound = 0
        case ParameterIntConversionFailed = 1
        case UrlGroupNotFound = 2
      }
    }

    public func urlGroup(name: String) -> Result<String, NSError> {
      if let result = urlGroups[name] {
        return success(result)
      } else {
        return failure(NSError(domain: Constants.HttpRequestDomain,
                               code: Constants.ErrorCode.UrlGroupNotFound.rawValue,
                               userInfo: ["message": "Url Group '\(name)' not found in \(url)"]))
      }
    }

    public func params(name: String) -> [String] {
      return reduce(urlParams, []) {
        if $1.0 == name {
          return $0 + [$1.1]
        } else {
          return $0
        }
      }
    }

    public func param(name: String) -> Result<String, NSError> {
      if let result = params(name).first {
        return success(result)
      } else {
        return failure(NSError(domain: Constants.HttpRequestDomain,
                               code: Constants.ErrorCode.ParameterNotFound.rawValue,
                               userInfo: ["message": "Parameter '\(name)' not found in \(url)"]))
      }
    }

    public func intParam(name: String) -> Result<Int, NSError> {
      return param(name).flatMap { value in
        if let int = value.toInt() {
          return success(int)
        } else {
          return failure(NSError(domain: Constants.HttpRequestDomain,
                                 code: Constants.ErrorCode.ParameterIntConversionFailed.rawValue,
                                 userInfo: ["message": "Unable to convert \(name)=\(value) to Int in \(self.url)"]))
        }
      }
    }
}
