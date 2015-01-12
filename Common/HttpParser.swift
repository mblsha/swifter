//
//  HttpParser.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpParser {

    func nextHttpRequest(socket: SocketReader, error:NSErrorPointer = nil) -> HttpRequest? {
        if let statusLine = socket.nextLine(error) {
            let statusTokens = split(statusLine, { $0 == " " })
            if ( statusTokens.count < 3 ) {
                if error != nil { error.memory = SocketReader.err("Invalid status line: \(statusLine)") }
                return nil
            }
            let method = statusTokens[0]
            let path = statusTokens[1]
            let urlParams = HttpParser.extractUrlParams(path)
            // TODO extract query parameters
            if let headers = nextHeaders(socket, error: error) {
                // TODO detect content-type and handle:
                // 'application/x-www-form-urlencoded' -> Dictionary
                // 'multipart' -> Dictionary
                if let contentSize = headers["content-length"]?.toInt() {
                    let body = socket.nextData(contentSize, error: error)
                    return HttpRequest(url: path, urlGroups: [String:String](), urlParams: urlParams, method: method, headers: headers, body: body)
                }
                return HttpRequest(url: path, urlGroups: [String:String](), urlParams: urlParams, method: method, headers: headers, body: nil)
            }
        }
        return nil
    }

    public class func extractUrlParams(url: String) -> [(String, String)] {
        if url.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "?")) == nil {
            return []
        }
        if let query = split(url, { $0 == "?" }).last {
            return map(split(query, { $0 == "&" }), { (param:String) -> (String, String) in
                let tokens = split(param, { $0 == "=" })
                if tokens.count >= 2 {
                    let key = tokens[0].stringByRemovingPercentEncoding
                    let value = tokens[1].stringByRemovingPercentEncoding
                    if key != nil && value != nil { return (key!, value!) }
                }
                return ("","")
            })
        }
        return []
    }

    private func nextHeaders(socket: SocketReader, error:NSErrorPointer) -> Dictionary<String, String>? {
        var headers = Dictionary<String, String>()
        while let headerLine = socket.nextLine(error) {
            if ( headerLine.isEmpty ) {
                return headers
            }
            let headerTokens = split(headerLine, { $0 == ":" })
            if ( headerTokens.count >= 2 ) {
                // RFC 2616 - "Hypertext Transfer Protocol -- HTTP/1.1", paragraph 4.2, "Message Headers":
                // "Each header field consists of a name followed by a colon (":") and the field value. Field names are case-insensitive."
                // We can keep lower case version.
                let headerName = headerTokens[0].lowercaseString
                let headerValue = headerTokens[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if ( !headerName.isEmpty && !headerValue.isEmpty ) {
                    headers.updateValue(headerValue, forKey: headerName)
                }
            }
        }
        return nil
    }

    func supportsKeepAlive(headers: Dictionary<String, String>) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
        }
        return false
    }
}
