//
//  SocketReader.swift
//  Swifter
//
//  Created by Michail Pishchagin on 05.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

class SocketReader {
  private let socket: CInt?

  init(socket: CInt?) {
    self.socket = socket
  }

  class func err(reason: String) -> NSError {
    return NSError(domain: "SocketReader", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
  }

  // result >= when everything's fine
  // result == -1 on error
  func nextUInt8() -> Int {
    var buffer = [UInt8](count: 1, repeatedValue: 0);
    let next = recv(socket!, &buffer, UInt(buffer.count), 0)
    if next <= 0 { return next }
    return Int(buffer[0])
  }

  func nextRawLine(error: NSErrorPointer) -> NSData? {
    var result = NSMutableData(length: 0)!
    var characters: String = ""
    var n = 0
    do {
      n = nextUInt8()
      if ( n > 13 /* CR */ ) {
        result.appendBytes(&n, length: 1)
      }
    } while ( n > 0 && n != 10 /* NL */)
    if ( n == -1 && characters.isEmpty ) {
      if error != nil { error.memory = Socket.lastErr("recv(...) failed.") }
      return nil
    }
    return result
  }

  func nextData(size: Int , error: NSErrorPointer) -> NSData? {
    var bytes = UnsafeMutablePointer<UInt8>.alloc(size)
    var success = true
    var counter = 0;

    while counter < size {
      var c = nextUInt8()
      if c < 0 {
        if error != nil {
          error.memory = SocketReader.err("IO error while reading body")
        }
        success = false
        break
      }
      bytes[counter++] = UInt8(c)
    }

    if success {
      let result = NSData(bytes: bytes, length: size)
      free(bytes)
      return result
    } else {
      free(bytes)
      return nil
    }
  }

  func nextLine(error: NSErrorPointer) -> String? {
    if let data = nextRawLine(error) {
      return NSString(data: data, encoding: NSUTF8StringEncoding)!
    } else {
      return nil
    }
  }
}

class MockSocketReader: SocketReader {
  private let bytes: UnsafePointer<UInt8>
  private let data: NSData
  private var offset: Int = 0

  init(data: String) {
    self.data = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    self.bytes = UnsafePointer<UInt8>(self.data.bytes)
    super.init(socket: nil)
  }

  override func nextUInt8() -> Int {
    if offset < data.length {
      return Int(bytes[offset++])
    }
    return -1
  }
}
