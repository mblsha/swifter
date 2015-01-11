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
    return NSMakeRange(0, (self as NSString).length)
  }

  var urlRangeWithoutParams: NSRange {
    let questionMarkRange = (self as NSString).rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "?"))
    var result = fullRange
    if questionMarkRange.location != NSNotFound {
      result.length = questionMarkRange.location
    }
    return result
  }

  func capturedGroups(expression: NSRegularExpression) -> [String] {
    var capturedGroups = [String]()
    if let result = expression.firstMatchInString(self, options: NSMatchingOptions(), range: fullRange) {
      for var i = 1 ; i < result.numberOfRanges ; ++i {
        let group = (self as NSString).substringWithRange(result.rangeAtIndex(i))
        capturedGroups.append(group)
      }
    }
    return capturedGroups
  }
}
