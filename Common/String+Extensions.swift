//
//  String+Extensions.swift
//  Swifter
//
//  Created by Michail Pishchagin on 07.01.15.
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

extension String {
  var fullRange: NSRange {
    return NSMakeRange(0, countElements(self))
  }

  func capturedGroups(expression: NSRegularExpression) -> [String] {
    var capturedGroups = [String]()
    if let result = expression.firstMatchInString(self, options: NSMatchingOptions(), range: fullRange) {
      let nsValue: NSString = self
      for var i = 1 ; i < result.numberOfRanges ; ++i {
        if let group = nsValue.substringWithRange(result.rangeAtIndex(i)).stringByRemovingPercentEncoding {
          capturedGroups.append(group)
        }
      }
    }
    return capturedGroups
  }
}
