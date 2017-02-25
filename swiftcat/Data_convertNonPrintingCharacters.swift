//
//  FileHandle_writeDisplayingNonPrintingCharacters.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson. All rights reserved.
//

import Foundation

public struct NonPrintingCharacterConversionOptions: OptionSet {
    public let rawValue: Int

    public static let none = NonPrintingCharacterConversionOptions(rawValue: 0)
    public static let tabs = NonPrintingCharacterConversionOptions(rawValue: 1 << 0)
    public static let endOfLine = NonPrintingCharacterConversionOptions(rawValue: 1 << 1)
    public static let hex = NonPrintingCharacterConversionOptions(rawValue: 1 << 2)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum Ascii {
    static let linefeed = UInt8(0x0a) // LF
    static let dollar   = UInt8(0x24) // $
    static let hyphen   = UInt8(0x2d) // -
    static let zero     = UInt8(0x30) // 0
    static let less     = UInt8(0x3c) // <
    static let greater  = UInt8(0x3e) // >
    static let question = UInt8(0x3f) // ?
    static let at       = UInt8(0x40) // @
    static let I        = UInt8(0x49) // I
    static let M        = UInt8(0x4d) // M
    static let caret    = UInt8(0x5e) // ^
    static let a        = UInt8(0x61) // a
}

extension Data {
    /// Return a copy of the data, with non-printing ASCII characters transformed to printable representations.
    ///
    /// If `NonPrintingCharacterConversionOptions.hex` is specified, then non-printing
    /// characters are converted to `<XX>`, where `XX` are hexadecimal digits.
    /// Otherwise, non-printing characters are converted as follows:
    ///
    /// - Control characters are converted to `^X` for control-X.
    /// - The DEL character (0x7f) are converted to `^?`.
    /// - Non-ASCII characters (with the high bit set) are converted to `M-` (for meta) followed by the character for the low 7 bits.
    ///
    /// If `NonPrintingCharacterConversionOptions.tab` is specified, then a TAB character (0x09)
    /// is converted to `^I`. Otherwise, there is no conversion of TAB characters.
    ///
    /// If `NonPrintingCharacterConversionOptions.endOfLine` is specified, then a LF character
    /// (0x0a) is converted to a dollar sign (`$`) followed by LF. Otherwise, there is no
    /// conversion of LF characters.
    public func convertingNonPrintingCharacters(options: NonPrintingCharacterConversionOptions) -> Data {
        var result = Data()

        func appendHexRepresentation(_ byte: UInt8) {
            func hexDigit(_ nibble: UInt8) -> UInt8 {
                assert(nibble < 16)
                switch nibble {
                case 0...9:
                    return nibble + Ascii.zero
                default:
                    return (nibble - 10) + Ascii.a
                }
            }
            
            result.append(Ascii.less)
            result.append(hexDigit(byte >> 4))
            result.append(hexDigit(byte & 0x0f))
            result.append(Ascii.greater)
        }

        func append7BitCharacterRepresentation(_ byte: UInt8) {
            switch byte {

            case 0x00...0x08, 0x0b...0x1f:
                if options.contains(.hex) {
                    appendHexRepresentation(byte)
                }
                else {
                    result.append(Ascii.caret)
                    result.append(Ascii.at + byte)
                }

            case 0x09:
                if options.contains(.tabs) {
                    if options.contains(.hex) {
                        appendHexRepresentation(byte)
                    }
                    else {
                        result.append(Ascii.caret)
                        result.append(Ascii.I)
                    }
                }
                else {
                    result.append(byte)
                }

            case 0x0a:
                if options.contains(.endOfLine) {
                    result.append(Ascii.dollar)
                }
                result.append(byte)

            case 0x7f:
                if options.contains(.hex) {
                    appendHexRepresentation(byte)
                }
                else {
                    result.append(Ascii.caret)
                    result.append(Ascii.question)
                }

            default:
                result.append(byte)
            }
        }

        for byte in self {
            if byte & 0x80 != 0 {
                if options.contains(.hex) {
                    appendHexRepresentation(byte)
                }
                else {
                    result.append(Ascii.M)
                    result.append(Ascii.hyphen)
                    append7BitCharacterRepresentation(byte & 0x7f)
                }
            }
            else {
                append7BitCharacterRepresentation(byte)
            }
        }

        return result
    }
}
