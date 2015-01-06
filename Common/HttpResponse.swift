//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponseBody {

    case JSON(AnyObject)
    case XML(AnyObject)
    case PLIST(AnyObject)
    case HTML(String)
    case RAW([String:AnyObject], NSData?)

    func headers() -> [String:AnyObject] {
        switch self {
        case .JSON:
            return ["Content-Type": "application/json; charset=utf-8"]
        case .RAW(let headers, _):
            return headers
        default:
            return [String:String]()
        }
    }

    func dataString() -> String? {
        switch self {
        case .JSON(let object):
            if NSJSONSerialization.isValidJSONObject(object) {
                var serializationError: NSError?
                if let json = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(), error: &serializationError) {
                    if let string = NSString(data: json, encoding: NSUTF8StringEncoding) {
                        return string.stringByReplacingOccurrencesOfString("\\/", withString: "/")
                    }
                }
                return "Serialization error: \(serializationError)"
            }
            return "Invalid object to serialise."
        case .XML(let data):
            return "XML serialization not supported."
        case .PLIST(let object):
            let format = NSPropertyListFormat.XMLFormat_v1_0
            if NSPropertyListSerialization.propertyList(object, isValidForFormat: format) {
                var serializationError: NSError?
                if let plist = NSPropertyListSerialization.dataWithPropertyList(object, format: format, options: 0, error: &serializationError) {
                    return NSString(data: plist, encoding: NSUTF8StringEncoding)
                }
                return "Serialisation error: \(serializationError)"
            }
            return "Invalid object to serialise."
        case .RAW(_, _):
            fatalError("Use data() for .RAW HttpResponse")
            return nil
        case .HTML(let body):
            return "<html><body>\(body)</body></html>"
        }
    }

    func data() -> NSData? {
      switch self {
      case .RAW(_, let body):
        return body
      default:
        return dataString()?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
      }
    }
}

public enum HttpResponse {

    case OK(HttpResponseBody), Created, Accepted
    case MovedPermanently(String)
    case BadRequest, Unauthorized, Forbidden, NotFound
    case InternalServerError
    case Custom(Int, HttpResponseBody)
    case RAW(Int, NSData)

    func statusCode() -> Int {
        switch self {
        case .OK(_)                 : return 200
        case .Created               : return 201
        case .Accepted              : return 202
        case .MovedPermanently      : return 301
        case .BadRequest            : return 400
        case .Unauthorized          : return 401
        case .Forbidden             : return 403
        case .NotFound              : return 404
        case .InternalServerError   : return 500
        case .Custom(let code, _)   : return code
        case .RAW(let code, _)      : return code
        }
    }

    func reasonPhrase() -> String {
        switch self {
        case .OK(_)                 : return "OK"
        case .Created               : return "Created"
        case .Accepted              : return "Accepted"
        case .MovedPermanently      : return "Moved Permanently"
        case .BadRequest            : return "Bad Request"
        case .Unauthorized          : return "Unauthorized"
        case .Forbidden             : return "Forbidden"
        case .NotFound              : return "Not Found"
        case .InternalServerError   : return "Internal Server Error"
        case .Custom(_,_)           : return "Custom"
        case .RAW(_,_)              : return "Custom"
        }
    }

    func headers() -> [String: AnyObject] {
        var headers = [String: AnyObject]()
        switch self {
        case .OK(let body):
            for i in body.headers() ?? [String: AnyObject]() {
              headers[i.0] = i.1
            }
        case .Custom(_, let body):
          for i in body.headers() ?? [String: AnyObject]() {
            headers[i.0] = i.1
          }
        default: break
        }
        headers["Server"] = "Swifter"
        switch self {
        case .MovedPermanently(let location) : headers["Location"] = location
        default:[]
        }
        return headers
    }

    func body() -> NSData? {
        switch self {
        case .OK(let body)      : return body.data()
        case .Custom(_,let body): return body.data()
        case .RAW(_, let data)  : return data
        default                 : return nil
        }
    }
}
