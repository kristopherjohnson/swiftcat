swiftcat
========

`swiftcat` is a simple re-implementation of the venerable UNIX [cat(1)](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/cat.1.html) utility in Swift.

As such, it is no more useful than your system's built-in `cat`, but I did this as an exercise in writing some reusable Swift code for parsing command-line options and traversing files.

It is mostly compatible with the built-in `cat`, so you can `alias cat=swiftcat` and be pretty happy with it. But `swiftcat` does not implement the `-s` or `-u` options, and its output of non-printing characters does not exactly match that of `cat`.

Building swiftcat
-----------------

Building `swiftcat` requires Xcode 8.x.

In the `swiftcat` directory, you can type `xcodebuild` and the product will be built at `./build/Release/swiftcat`

Running swiftcat
----------------

Running `swiftcat -h` will display a a usage hint and summary of available command-line options:

```
usage: swiftcat [-behntvx] [file ...]
options:
-b, --nonblank-line-numbers    Number the non-blank output lines, starting at 1.
-e, --display-eol              Display non-printing characters and a dollar sign ('$') at the end of each line.
-h, --help                     Show this help message.
-n, --line-numbers             Number the output lines, starting at 1.
-t, --display-tabs             Display non-printing characters, and display tab characters as '^I'.
-v, --display-nonprinting      Display non-printing characters so they are visible.
-x, --display-hex              Display non-printing characters in hexadecimal notation.
```

As with `cat`, if a single dash (`-`) is specified as a filename, or if no arguments are given, then `swiftcat` reads from standard input.

Use `man cat` for more information about what the options mean.

Note that the `-h` and `-x` options are extensions not supported by the original `cat`. The long option names are also not supported by `cat`.

