//
//  File.swift
//  
//
//  Created by user on 1/08/21.
//

import Foundation

public enum Lox {

    public static func main(args: [String]) throws {
        if args.count > 1 {
            print("Usage: slox [script]")
            exit(64)
        } else if args.count == 1 {
            try runFile(args[0])
        } else {
            try runPrompt()
        }
    }
}

private extension Lox {

    static var hadError = false

    static func runFile(_ file: String) throws {
        let contents = try String(contentsOfFile: file)
        try run(contents)

        if hadError { exit(65) }
    }

    static func runPrompt() throws {
        while true {
            print("> ", terminator: "")

            guard let line = readLine() else { continue }
            try run(line)
        }
    }

    static func run(_ str: String) throws {
        let scanner = Scanner(source: str)
        let tokens = scanner.scanTokens()

        let parser = Parser(tokens: tokens)
        let expression = parser.parse()

        // Stop if there was a syntax error
        if hadError { return }

        ASTPrinter(strategy: .infix).print(expression!)
    }
}

internal extension Lox {

    static func error(line: Int, message: String) {
        report(line: line, location: "", message: message)
    }

    static func error(token: Token, message: String) {
        if token.type == .EOF {
            report(line: token.line, location: "at end", message: message)
        } else {
            let location = "at '\(token.lexeme)'"
            report(line: token.line, location: location, message: message)
        }
    }

    private static func report(line: Int, location: String, message: String) {
        // TODO: send this to STDERR
        print("[line \(line)] Error \(location): \(message)")
        hadError = true
    }
}
