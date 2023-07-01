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
                })
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

}
