//
//  DataInputStream.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson
//

import Foundation

/// A `DataInputStream` implements a `readData(ofLength:)` method.
public protocol DataInputStream {
    /// Synchronously reads data up to the specified number of bytes.
    func readData(ofLength length: Int) -> Data
}

// FileHandle implements readData(ofLength:).
extension FileHandle: DataInputStream { }

/// Adapts a C stdio `FILE*` as a `DataInputStream`.
public class StdioInputStream: DataInputStream {

    var file: UnsafeMutablePointer<FILE>
    let name: String

    /// End-of-file indicator.
    public var isAtEOF: Bool {
        return feof(file) != 0
    }

    /// Error indicator.
    ///
    /// - returns: Non-zero error code if an error has been detected.
    public var error: Int32 {
        return ferror(file)
    }

    /// Constructor
    ///
    /// - parameter file: Pointer to open FILE.
    /// - parameter name: Label for the file, used in error messages.
    public init(file: UnsafeMutablePointer<FILE>, name: String = "<unnamed file>") {
        self.file = file
        self.name = name
    }

    /// Synchronously reads data up to the specified number of bytes.
    public func readData(ofLength length: Int) -> Data {
        var data = Data(count: length)
        let readCount = data.withUnsafeMutableBytes { (buffer) -> Int in
            return fread(buffer, 1, length, file)
        }
        if readCount < 1 {
            // TODO: It's ugly to have this use of stderr here.
            // Would be cleaner to provide some sort of error-handling
            // delegate, or just treat errors as EOF.
            if error != 0 {
                fputs("\(name): Read error", stderr)
                clearError()
            }
            return Data()
        }
        else {
            data.count = readCount
            return data
        }
    }

    /// Clear error and EOF indicators for the file.
    public func clearError() {
        clearerr(file)
    }
}

extension DataInputStream {

    /// Return an iterator over the bytes in the file.
    ///
    /// - returns: An iterator for `UInt8` elements.
    public func bytes() -> DataInputStreamByteIterator {
        return DataInputStreamByteIterator(dataInputStream: self)
    }

    /// Return an iterator over the lines in the file.
    ///
    /// A "line" is a sequence of bytes ending in "\n" or the specified delimiter,
    /// unless at the end of file.
    ///
    /// - parameter delimiter: Byte value that marks end of line. Defaults to LF.
    ///
    /// - returns: An iterator for `Data` elements.
    public func lines(delimiter: UInt8 = 0x0a) -> DataInputStreamLineIterator {
        return DataInputStreamLineIterator(dataInputStream: self, delimiter: delimiter)
    }

    /// Return an iterator over fixed-length blocks read from the file.
    ///
    /// - parameter bytesPerBlock: Length of each block.
    ///
    /// - returns: An iterator for `Data` elements.
    public func blocks(ofLength bytesPerBlock: Int) -> DataInputStreamBlockIterator {
        return DataInputStreamBlockIterator(dataInputStream: self, bytesPerBlock: bytesPerBlock)
    }
}

/// An iterator over the bytes read from a DataInputStream.
public struct DataInputStreamByteIterator: IteratorProtocol, Sequence {
    let blockIterator: DataInputStreamBlockIterator
    var block: Data?
    var dataIterator: Data.Iterator?

    public init(dataInputStream: DataInputStream) {
        self.blockIterator = dataInputStream.blocks(ofLength: 4096)
        self.block = nil
        self.dataIterator = nil
    }

    /// Read next byte.
    ///
    /// - returns: Byte, or nil if at end of file.
    public mutating func next() -> UInt8? {
        if dataIterator != nil {
            if let byte = dataIterator!.next() {
                return byte
            }
        }

        if let nextBlock = blockIterator.next() {
            block = nextBlock
            dataIterator = block!.makeIterator()
            return dataIterator!.next()
        }

        return nil
    }
}

/// An iterator over the lines read from a DataInputStream.
///
/// A "line" is a sequence of bytes ending with a LF byte or specified byte value.
/// Each returned line includes the delimiter, unless end-of-file was reached.
public struct DataInputStreamLineIterator: IteratorProtocol, Sequence {
    var byteIterator: DataInputStreamByteIterator
    let delimiter: UInt8

    /// Constructor
    ///
    /// - parameter dataInputStream: Open file handle.
    /// - parameter delimiter: Byte value that marks end of line.
    public init(dataInputStream: DataInputStream, delimiter: UInt8 = 0x0a) {
        self.byteIterator = dataInputStream.bytes()
        self.delimiter = delimiter
    }

    /// Read next line from file.
    ///
    /// - returns: Next line, or nil if at end of file.
    public mutating func next() -> Data? {
        var byte = byteIterator.next()
        if byte == nil {
            return nil
        }

        var lineData = Data()
        lineData.append(byte!)

        while byte != delimiter {
            byte = byteIterator.next()
            if byte == nil {
                break
            }
            lineData.append(byte!)
        }

        return lineData
    }
}

/// An iterator that reads fixed-length blocks of data from a DataInputStream.
public struct DataInputStreamBlockIterator: IteratorProtocol, Sequence {
    let dataInputStream: DataInputStream
    let bytesPerBlock: Int

    /// Constructor.
    ///
    /// - parameter dataInputStream: Open file handle.
    /// - parameter bytesPerBlock: Number of bytes in each fixed-size block.
    public init(dataInputStream: DataInputStream, bytesPerBlock: Int) {
        assert(bytesPerBlock > 0)

        self.dataInputStream = dataInputStream
        self.bytesPerBlock = bytesPerBlock
    }

    /// Read next block.
    ///
    /// - returns: `Data`, or `nil` if at end of file.
    public func next() -> Data? {
        var block = dataInputStream.readData(ofLength: bytesPerBlock)
        if block.count == bytesPerBlock {
            return block
        }
        else if block.count == 0 {
            return nil
        }

        // Keep reading until we fill the block or hit end-of-file.
        var nextData = dataInputStream.readData(ofLength: bytesPerBlock - block.count)
        while nextData.count > 0 {
            block.append(nextData)
            if block.count == bytesPerBlock {
                return block
            }
            nextData = dataInputStream.readData(ofLength: bytesPerBlock - block.count)
        }
        return block
    }
}
