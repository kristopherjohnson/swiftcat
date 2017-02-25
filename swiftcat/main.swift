//
//  main.swift
//  swiftcat
//
//  Copyright © 2017 Kristopher Johnson
//

import Foundation

let bufferSize = 4 * 1024

var stdout = FileHandle.standardOutput
var stderr = FileHandle.standardError

/// Errors that can be thrown by this application.
enum AppError: Error, CustomStringConvertible {
    case unableToOpenFile(path: String)
    case fatalError(message: String)

    public var description: String {
        switch self {
        case .unableToOpenFile(let path): return "\(path): unable to open file"
        case .fatalError(let message):    return "fatal error: \(message)"
        }
    }
}

/// Display a brief usage message to standard error.
func showUsage() {
    print("usage: swiftcat [-behnstvx] [file ...]", to: &stderr)
}

/// Display information for command-line options to standard error.
func showOptionsHelp(optionDefinitions: [CommandLineOptionDefinition]) {
    print("options:", to: &stderr)
    printHelp(optionDefinitions: optionDefinitions, to: &stderr, firstColumnWidth: 30)
}

/// Copy a file to standard output.
func printFile(fileHandle: FileHandle) {
    for data in fileHandle.blocks(ofLength: bufferSize) {
        stdout.write(data)
    }
}

/// Copy a file to standard output, converting non-printing characters to visible forms.
func printFile(fileHandle: FileHandle,
               displayNonPrintingCharactersWithOptions options: NonPrintingCharacterConversionOptions) {
    for data in fileHandle.blocks(ofLength: bufferSize) {
        stdout.write(data.convertingNonPrintingCharacters(options: options))
    }
}

/// Copy a file to standard output, with line numbers.
func printFileWithLineNumbers(fileHandle: FileHandle, skipBlankLines: Bool) {
    var nextLineNumber = 1
    for lineData in fileHandle.lines() {
        if skipBlankLines && isBlankLine(data: lineData) {
            stdout.write(lineData)
        }
        else {
            write(data: lineData, withLineNumber: nextLineNumber)
            nextLineNumber += 1
        }
    }
}

/// Copy a file to standard output, with line numbers, converting non-printing characters to visible forms..
func printFileWithLineNumbers(fileHandle: FileHandle,
                              skipBlankLines: Bool,
                              displayNonPrintingCharactersWithOptions options: NonPrintingCharacterConversionOptions) {
    var nextLineNumber = 1
    for lineData in fileHandle.lines() {
        if skipBlankLines && isBlankLine(data: lineData) {
            stdout.write(lineData)
        }
        else {
            let data = lineData.convertingNonPrintingCharacters(options: options)
            write(data: data, withLineNumber: nextLineNumber)
            nextLineNumber += 1
        }
    }
}

/// Determine whether data is an empty line.
///
/// - returns: `true` if `data` is empty or consists only of a newline.
func isBlankLine(data: Data) -> Bool {
    if data.count == 0 {
        return true
    }

    if data.count == 1 {
        if let firstByte = data.first {
            return firstByte == 0x0a
        }
    }

    return false
}

/// Write data to standard output prefixed with a line number.
func write(data: Data, withLineNumber lineNumber: Int) {
    let lineNumberString = String(format: "%6d  ", lineNumber)
    if let lineNumberData = lineNumberString.data(using: .utf8) {
        stdout.write(lineNumberData)
        stdout.write(data)
    }
    else {
        fatalError("unable to convert string to UTF8")
    }
}

func main() {
    do {
        let optionDefinitions = [
            CommandLineOptionDefinition(
                name: "nonblank-line-numbers",
                letter: "b",
                valueType: .noValue,
                briefHelp: "Number the non-blank output lines, starting at 1."),

            CommandLineOptionDefinition(
                name: "display-eol",
                letter: "e",
                valueType: .noValue,
                briefHelp: "Display non-printing characters and a dollar sign ('$') at the end of each line."),

            CommandLineOptionDefinition(
                name: "help",
                letter: "h",
                valueType: .noValue,
                briefHelp: "Show this help message."),

            CommandLineOptionDefinition(
                name: "line-numbers",
                letter: "n",
                valueType: .noValue,
                briefHelp: "Number the output lines, starting at 1."),

            CommandLineOptionDefinition(
                name: "display-tabs",
                letter: "t",
                valueType: .noValue,
                briefHelp: "Display non-printing characters, and display tab characters as '^I'."),

            CommandLineOptionDefinition(
                name: "display-nonprinting",
                letter: "v",
                valueType: .noValue,
                briefHelp: "Display non-printing characters so they are visible."),

            CommandLineOptionDefinition(
                name: "display-hex",
                letter: "x",
                valueType: .noValue,
                briefHelp: "Display non-printing characters in hexadecimal notation."),
        ]

        let args = try CommandLineParseResult(arguments: CommandLine.arguments,
                                              optionDefinitions: optionDefinitions)

        if args.isPresent(optionNamed: "help") {
            showUsage()
            showOptionsHelp(optionDefinitions: optionDefinitions)
            exit(0)
        }

        if args.parsedArguments.count < 1 {
            showUsage()
            exit(1)
        }

        var displayLineNumbers = false
        var skipBlankLines = false
        var displayNonPrintingCharacters = false
        var nonPrintingCharacterOptions = NonPrintingCharacterConversionOptions.none

        if args.isPresent(optionNamed: "line-numbers") {
            displayLineNumbers = true
        }

        if args.isPresent(optionNamed: "nonblank-line-numbers") {
            displayLineNumbers = true
            skipBlankLines = true
        }

        if args.isPresent(optionNamed: "display-nonprinting") {
            displayNonPrintingCharacters = true
        }

        if args.isPresent(optionNamed: "display-eol") {
            displayNonPrintingCharacters = true
            nonPrintingCharacterOptions.insert(.endOfLine)
        }

        if args.isPresent(optionNamed: "display-tabs") {
            displayNonPrintingCharacters = true
            nonPrintingCharacterOptions.insert(.tabs)
        }

        if args.isPresent(optionNamed: "display-hex") {
            displayNonPrintingCharacters = true
            nonPrintingCharacterOptions.insert(.hex)
        }

        for path in args.parsedArguments {
            guard let fileHandle = FileHandle(forReadingAtPath: path) else {
                throw AppError.unableToOpenFile(path: path)
            }

            if displayLineNumbers {
                if displayNonPrintingCharacters {
                    printFileWithLineNumbers(fileHandle: fileHandle,
                                             skipBlankLines: skipBlankLines,
                                             displayNonPrintingCharactersWithOptions: nonPrintingCharacterOptions)
                }
                else {
                    printFileWithLineNumbers(fileHandle: fileHandle,
                                             skipBlankLines: skipBlankLines)
                }
            }
            else if displayNonPrintingCharacters {
                printFile(fileHandle: fileHandle,
                          displayNonPrintingCharactersWithOptions: nonPrintingCharacterOptions)
            }
            else {
                printFile(fileHandle: fileHandle)
            }
        }
    }
    catch let error {
        print("swiftcat: \(error)", to: &stderr)
        exit(1)
    }
}

main()

