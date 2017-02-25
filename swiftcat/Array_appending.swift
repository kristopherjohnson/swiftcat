//
//  Array_appending.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson
//

import Foundation

extension Array {
    /// Returns a new `Array` made by appending a given element to the `Array`.
    public func appending(_ newElement: Element) -> Array {
        var a = Array(self)
        a.append(newElement)
        return a
    }
}
