import XCTest
@testable import PolCalRuntime

final class PolCalTests: XCTestCase {
    func execute(_ code: String) -> (PolCalValue, String) {
        var logs: [String] = []
        let api: [String: PolCalValue] = [
            "Print": .unbound(PolCalFunction(
                name: "Print",
                arity: 1) { v in
                    logs.append(v[0].toString())
                    return v[0]
                }),
            "Repeat": .unbound(PolCalFunction(
                name: "Repeat",
                arity: 2) { v in
                    guard case let .integer(t) = v[0] else {
                        fatalError("Repeat abuse (v[0] not an integer).")
                    }
                    return (0..<t).map { x in
                        v[1].function!.apply(.integer(x))
                    }.last ?? .none
                }),
        ]
        let ret = PolCalRuntime.execute(code, api: api)
        return (ret, logs.joined(separator: "\n"))
    }

    func check(_ cases: [(String, (PolCalValue, String))]) {
        cases.forEach { x in
            let (code, (ret, logs)) = x
            let (returned, logged) = self.execute(code)
            XCTAssertEqual(returned, ret, "return value for '\(code)'")
            XCTAssertEqual(logged, logs, "logged value for '\(code)'")
        }
    }

    func testNormalApplicationOrder() {
        let cases: [(String, (PolCalValue, String))] = [
            ("Add 1 Multiply 3 4", (.integer(13), "")),
            ("Add Print 1 Multiply 3 4", (.integer(13), "1")),
            ("Print Add 1 Multiply 3 4", (.integer(13), "13")),
            ("Add 1 Print Multiply 3 4", (.integer(13), "12")),
        ]
        check(cases)
    }

    func testNumberParsing() {
        let cases: [(String, (PolCalValue, String))] = [
            ("3", (.integer(3), "")),
            ("-1", (.integer(-1), "")),
            ("12345", (.integer(12345), "")),
            (".1", (.double(0.1), "")),
            ("1.", (.double(1.0), "")),
            ("3.14", (.double(3.14), "")),
        ]
        check(cases)
    }

    func testAddition() {
        let d7 = 3.0 + 4.0
        let cases: [(String, (PolCalValue, String))] = [
            ("Add 3 4", (.integer(7), "")),
            ("Add 3.0 4", (.double(d7), "")),
            ("Add 3 4.0", (.double(d7), "")),
            ("Add 3.0 4.0", (.double(d7), "")),
            ("Add 3.0 -4.0", (.double(3.0-4.0), "")),
        ]
        check(cases)
    }

    func testMultiplication() {
        let d12 = 3.0 * 4.0
        let cases: [(String, (PolCalValue, String))] = [
            ("Multiply 3 4", (.integer(12), "")),
            ("Multiply 3.0 4", (.double(d12), "")),
            ("Multiply 3 4.0", (.double(d12), "")),
            ("Multiply 3.0 4.0", (.double(d12), "")),
            ("Multiply 3.0 -4.0", (.double(3.0 * -4.0), "")),
        ]
        check(cases)
    }

    func testCurrying() {
        let Add = standardLibrary["Add"]!.function!
        let Multiply = standardLibrary["Multiply"]!.function!
        let cases: [(String, (PolCalValue, String))] = [
            ("Add 3", (Add.apply(.integer(3)), "")),
            ("(Add 3) 4", (.integer(7), "")),
            ("Repeat 3 ( Print )", (.integer(2), "0\n1\n2")),
            ("Add Multiply 3", (Add.apply(Multiply.apply(.integer(3))), ""))
        ]
        check(cases)
    }

    func testBasicClosures() {
        let Add = standardLibrary["Add"]!.function!
        let Multiply = standardLibrary["Multiply"]!.function!
        let cases: [(String, (PolCalValue, String))] = [
            ("x (Add x) 3", (Add.apply(.integer(3)), "")),
            ("x (Add x) 3 4", (.integer(7), "")),
            ("x Multiply (Add x 3) 4 7", (.integer((3 + 7)*4), "")),
        ]
        check(cases)
    }

    func testAckerman() {
        let True = standardLibrary["True"]!
        let cases: [(String, (PolCalValue, String))] = [
            // This one doesn't fully apply A so that eager evaluation works
            ("Equal 61 (((A A A) A m n (Equal m 0 (y + n 1) (x A A - 1 m Equal n 0 1 (A A m - 1 n))) 0) 3 3)", (True, "")),
            // This one requires the boolean functions to be lazy
            ("Equal 61 (((A A A) A m n Equal m 0 + n 1 (A A - 1 m Equal n 0 1 (A A m - 1 n))) 3 3)", (True, "")),
        ]
        check(cases)
    }

}
