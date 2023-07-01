import XCTest
@testable import PolCalRuntime

final class PolCalTests: XCTestCase {
    func execute(_ code: String) -> (PolCalValue, String) {
        var logs = ""
        let api: [String: PolCalValue] = [
            "Print": .unbound(PolCalFunction(
                name: "Print",
                arity: 1) { v in
                    logs += "\(v)"
                    return v[0]
                })
        ]
        let ret = PolCalRuntime.execute(code, api: api)
        return (ret, logs)
    }

    func testNormalApplicationOrder() {
        let tests: [(String, (PolCalValue, String))] = [
            ("Add 1 Multiply 3 4", (.integer(13), "")),
            ("Add Print 1 Multiply 3 4", (.integer(13), "1")),
            ("Print Add 1 Multiply 3 4", (.integer(13), "13")),
            ("Add 1 Print Multiply 3 4", (.integer(13), "12")),
        ]
        print("start test")
        tests.forEach { x in
            let (code, (ret, logs)) = x
            print("running...")
            let (returned, logged) = self.execute(code)
            print("runned")
            XCTAssertEqual(returned, ret, "change return value for '\(code)'")
            XCTAssertEqual(logged, logs, "logged value for '\(code)'")
        }
    }
}
