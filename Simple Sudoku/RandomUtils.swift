//
// Created by Jonas Theslöf on 2018-09-05.
// Copyright (c) 2018 Jonas Theslöf. All rights reserved.
//

import Foundation

extension Int {
    static func random() -> Int {
        return Int(arc4random())
    }

    static func random(_ upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper)))
    }

    static func random(_ range: CountableRange<Int>) -> Int {
        return Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound
    }

    static func random(_ range: CountableClosedRange<Int>) -> Int {
        return Int.random(range.lowerBound..<(range.upperBound + 1))
    }
}

extension Array {
    mutating func shuffle() {
        var newArray: [Element] = []
        while self.count > 0 {
            newArray.append(self.remove(at: Int.random(self.count)))
        }
        self = newArray
    }
}