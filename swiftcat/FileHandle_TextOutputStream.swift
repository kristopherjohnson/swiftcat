//
//  FileHandle_TextOutputStream.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson
//

import Foundation

extension FileHandle: TextOutputStream {
    /// Appends the given string to the stream.
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.write(data)
        }
        else {
            fatalError("unable to write to text output stream")
        }
    }
}
