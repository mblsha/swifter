//
//  SocketReader.swift
//  Swifter
//
//  Created by Michail Pishchagin on 05.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

struct SocketReader {
  private let socket: CInt

  init(socket: CInt) {
    self.socket = socket
  }

  func nextUInt8() -> Int {
    var buffer = [UInt8](count: 1, repeatedValue: 0);
    let next = recv(socket, &buffer, UInt(buffer.count), 0)
    if next <= 0 { return next }
    return Int(buffer[0])
  }

  func nextLine(error: NSErrorPointer) -> String? {
    var characters: String = ""
    var n = 0
    do {
      n = nextUInt8()
      if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
    } while ( n > 0 && n != 10 /* NL */)
    if ( n == -1 && characters.isEmpty ) {
      if error != nil { error.memory = Socket.lastErr("recv(...) failed.") }
      return nil
    }
    return characters
  }
}
