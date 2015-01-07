//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer
{
    public typealias Handler = HttpRequest -> HttpResponse

    struct Route {
        let expression: NSRegularExpression
        let name: String
        let urlGroupNames: [String]
        let handler: Handler

        // uses Rails-like syntax for naming routes: ":groupName" will be
        // added as a pattern that matches everything, except for forward slashes
        init(name: String, handler: Handler) {
            self.name = name
            self.handler = handler

            var pattern = name
            let groupExpression = NSRegularExpression(pattern: ":(\\w+)", options: NSRegularExpressionOptions(), error: nil)!
            self.urlGroupNames = []
            while true {
                let range = groupExpression.rangeOfFirstMatchInString(pattern, options: NSMatchingOptions(), range: pattern.fullRange)
                if range.location != NSNotFound {
                    let rangeWithoutColon = NSMakeRange(range.location + 1, range.length - 1)
                    urlGroupNames.append((pattern as NSString).substringWithRange(rangeWithoutColon))
                    pattern = (pattern as NSString).stringByReplacingCharactersInRange(range, withString: "([^/]+)")
                } else {
                    break
                }
            }

            self.expression = NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(), error: nil)!
        }

        func urlGroups(url: String) -> [String: String] {
            var capturedGroups = url.capturedGroups(expression)
            assert(capturedGroups.count == urlGroupNames.count)
            var result = [String:String]()
            for i in 0..<capturedGroups.count {
                result[urlGroupNames[i]] = capturedGroups[i]
            }
            return result
        }
    }

    var handlers: [Route] = []
    var acceptSocket: CInt = -1

    public subscript (name: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            if let newHandler = newValue {
                handlers.append(Route(name: name, handler: newHandler))
            }
        }
    }

    public func routes() -> [String] { return map(handlers, { $0.name }) }

    public init() {
    }

    public func start(listenPort: in_port_t = 8080, error: NSErrorPointer = nil, ipv4addr: String? = nil) -> Bool {
        releaseAcceptSocket()
        if let socket = Socket.tcpForListen(port: listenPort, error: error, ipv4addr: ipv4addr) {
            acceptSocket = socket
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                while let socket = Socket.acceptClientSocket(self.acceptSocket) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        let parser = HttpParser()
                        let socketReader = SocketReader(socket: socket)
                        while let request = parser.nextHttpRequest(socketReader) {
                            let keepAlive = parser.supportsKeepAlive(request.headers)
                            if let route = self.findRoute(request.url) {
                                let urlGroups = route.urlGroups(request.url)
                                let updatedRequest = HttpRequest(url: request.url, urlGroups: urlGroups, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body)
                                HttpServer.writeResponse(socket, response: route.handler(updatedRequest), keepAlive: keepAlive)
                            } else {
                                HttpServer.writeResponse(socket, response: HttpResponse.NotFound, keepAlive: keepAlive)
                            }
                            if !keepAlive { break }
                        }
                        Socket.release(socket)
                    })
                }
                self.releaseAcceptSocket()
            })
            return true
        }
        return false
    }

    func findRoute(url:String) -> Route? {
        return self.handlers.filter { route in
            let urlRange = url.fullRange
            let matchRange = route.expression.rangeOfFirstMatchInString(
                url,
                options: NSMatchingOptions(),
                range: urlRange)
            return matchRange.location != NSNotFound &&
                   matchRange.length == urlRange.length
        }.first
    }

    class func writeResponse(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        if let body = response.body() {
            Socket.writeStringASCII(socket, string: "Content-Length: \(body.length)\r\n")
        } else {
            Socket.writeStringASCII(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            Socket.writeStringASCII(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            Socket.writeStringASCII(socket, string: "\(name): \(value)\r\n")
        }
        Socket.writeStringASCII(socket, string: "\r\n")
        if let body = response.body() {
            Socket.writeData(socket, data: body)
        }
    }

    public func stop() {
        releaseAcceptSocket()
    }

    func releaseAcceptSocket() {
        if ( acceptSocket != -1 ) {
            Socket.release(acceptSocket)
            acceptSocket = -1
        }
    }
}

