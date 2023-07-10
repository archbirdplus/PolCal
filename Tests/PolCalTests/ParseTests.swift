import XCTest
@testable import PolCalRuntime

final class PolCalTests: XCTestCase {

    func checkParse(_ cases: [(String, String)]) {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
        let digits = "0123456789".map(String.init)
        var syntaxes: [String: SyntaxStyle] = [:]
        (digits + alphabet).forEach { name in
            syntaxes[name] = SyntaxStyle(
                name: .global(GlobalName(i: syntaxes.count, str: name)),
                arity: Int(name) ?? 0)
        }
        cases.forEach { pair in
            let (code, parsed) = pair
            let tokens = tokenize(code)
            // note: resolveSymbols has to create new SyntaxStyles for arguments
            let (litFuns, symbols) = resolveSymbols(tokens, syntaxes: syntaxes)
            let parseNode = parse(symbols)
            XCTAssertEqual(parseNode.debugDescription, parsed, "while parsing \(code)")
        }
    }

    func testFullApplication() {
        checkParse([
            ("3 2 A A B B", "[3 [2 A A] B B]"),
            ("1 1 A", "[1 [1 A]]"),
            ("2 1 A 1 A", "[2 [1 A] [1 A]]"),
        ])
    }

    func testPartialApplication() {
        checkParse([
            ("3 2 A A B", "[3 [2 A A] B]"),
            ("2 1 A", "[2 [1 A]]"),
            ("1 2 A", "[1 [2 A]]"),
        ])
    }

    // explicitly present saturated functions for the optimizer?
    func testOverApplication() {
        checkParse([
            ("3 A B C D", "[[3 A B C] D]"),
            ("2 (3 A B C D)", "[2 [[3 A B C] D]]"),
        ])
    }

    func testParenOverride() {
        checkParse([
            ("3 A (B C D)", "[3 A [B C D]]"),
            ("2 (3 A (B C D))", "[2 [3 A [B C D]]]"),
            ("2 (3 A B) C D)", "[[2 [3 A B] C] D]"),
        ])
    }

    func testNestedParenSimplification() {
        checkParse([
            ("A (A ((B)) ((A) A)))", "[A [A B [A A]]]"),
            ("A (B) ((A B))", "[A B [A B]]"),
        ])
    }

    func testLambdas() {
        checkParse([
            ("3 a b c A B C D", "[[3 a -> b -> c -> A B C] D]"),
            ("3 a b c a B C D", "[[3 a -> b -> c -> a B C] D]"),
            ("3 a b c (a B) C D", "[3 a -> b -> c -> [a B] C D]"),
            ("3 a b c 2 a b C D", "[3 a -> b -> c -> [2 a b] C D]"),
            ("3 a b c 2 a b C D E", "[[3 a -> b -> c -> [2 a b] C D] E]"),
        ])
    }

}
