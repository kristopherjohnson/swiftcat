//
//  FileHandle_Iterators.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson
//

import Foundation

extension FileHandle {

    /// Return an iterator over the bytes in the file.
    ///
    /// - returns: An iterator for UInt8 elements.
    public func bytes() -> FileHandleByteIterator {
        return FileHandleByteIterator(fileHandle: self)
    }

    /// Return an iterator over the lines in the file.
    ///
    /// A "line" is a String ending in "\n" or the specified delimiter,
    /// unless at the end of file.
    ///
    /// - parameter delimiter: Byte value that marks end of line. Defaults to LF.
    ///
    /// - returns: An iterator for Strings.
    public func lines(delimiter: UInt8 = 0x0a) -> FileHandleLineIterator {
        return FileHandleLineIterator(fileHandle: self, delimiter: delimiter)
    }

    /// Return an iterator over fixed-length blocks read from the file.
    ///
    /// - parameter bytesPerBlock: Length of each block.
    ///
    /// - returns: An iterator for Data elements.
    public func blocks(ofLength bytesPerBlock: Int) -> FileHandleBlockIterator {
        return FileHandleBlockIterator(fileHandle: self, bytesPerBlock: bytesPerBlock)
    }
}

/// An iterator over the bytes read from a FileHandle.
public struct FileHandleByteIterator: IteratorProtocol, Sequence {
    let fileHandle: FileHandle

    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    /// Read next byte.
    ///
    /// - returns: Byte, or nil if at end of file.
    public func next() -> UInt8? {
        return fileHandle.readData(ofLength: 1).first
    }
}

/// An iterator over the lines read from a FileHandle.
///
/// A "line" is a sequence of bytes ending with a LF byte or specified byte value.
/// Each returned line includes the delimiter, unless end-of-file was reached.
public struct FileHandleLineIterator: IteratorProtocol, Sequence {
    let fileHandle: FileHandle
    let delimiter: UInt8

    /// Constructor
    ///
    /// - parameter fileHandle: Open file handle.
    /// - parameter delimiter: Byte value that marks end of line.
    public init(fileHandle: FileHandle, delimiter: UInt8 = 0x0a) {
        self.fileHandle = fileHandle
        self.delimiter = delimiter
    }

    /// Read next line from file.
    ///
    /// - returns: Next line, or nil if at end of file.
    public func next() -> Data? {
        var readBuffer = readOneByte()
        if readBuffer.count == 0 {
            return nil
        }
        var lineData = readBuffer
        var byte = readBuffer.first!
        while byte != delimiter {
            readBuffer = readOneByte()
            if readBuffer.count == 0 {
                break
            }
            lineData.append(readBuffer)
            byte = readBuffer.first!
        }
        return lineData
    }

    /// Read next byte.
    ///
    /// - returns: Data containing one byte, or empty Data if at end of file.
    ///
    /// - TODO: This implementation uses `FileHandle.readData(ofLength: 1)` to read a byte at a time. There may be more performant ways to read the data.
    private func readOneByte() -> Data {
        return fileHandle.readData(ofLength: 1)
    }
}

/// An iterator that reads fixed-length blocks of data from a FileHandle.
public struct FileHandleBlockIterator: IteratorProtocol, Sequence {
    let fileHandle: FileHandle
    let bytesPerBlock: Int

    /// Constructor.
    ///
    /// - parameter fileHandle: Open file handle.
    /// - parameter bytesPerBlock: Number of bytes in each fixed-size block.
    public init(fileHandle: FileHandle, bytesPerBlock: Int) {
        assert(bytesPerBlock > 0)

        self.fileHandle = fileHandle
        self.bytesPerBlock = bytesPerBlock
    }

    /// Read next block.
    ///
    /// - returns: Data, or nil if at end of file.
    public func next() -> Data? {
        var block = fileHandle.readData(ofLength: bytesPerBlock)
        if block.count == bytesPerBlock {
            return block
        }
        else if block.count == 0 {
            return nil
        }

        // Keep reading until we fill the block or hit end-of-file.
        var nextData = fileHandle.readData(ofLength: bytesPerBlock - block.count)
        while nextData.count > 0 {
            block.append(nextData)
            if block.count == bytesPerBlock {
                return block
            }
            nextData = fileHandle.readData(ofLength: bytesPerBlock - block.count)
        }
        return block
    }
}
