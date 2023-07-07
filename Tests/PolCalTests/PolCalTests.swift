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

    func checkParseExpression(_ cases: [(String, String)]) {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
        let digits = "0123456789".map(String.init)
        var library = standardLibrary
        alphabet.forEach { name in
            library[name] = .unbound(PolCalFunction(
                name: name,
                arity: 0) { _ in
                .none
            })
        }
        digits.forEach {
            name in library[name] = .unbound(PolCalFunction(
                name: name,
                arity: Int(name)!) { _ in
                    .none 
                })
        }
        cases.forEach { pair in
            let (code, parsed) = pair
            let tokens = tokenize(code)
            let symbols = resolveSymbols(tokens, library: library)
            let expression = Expression.topLevel(symbols)
            XCTAssertEqual(expression.string, parsed, "while parsing \(code)")
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

    func testParenParsing() {
        let cases: [(String, String)] = [
            ("(A B) C", "((A B) C)"),
            ("1 B C", "((1 B) C)"),
            ("2 (B C) 2 (A) B", "((2 (B C) (2 (A) B)))"),
            ("(a a a)", "((a -> (get a) a -> ()))"),
            ("2 (x (x A))", "((2 (x -> ((get x) A))))"),
            ("2 (x (2 x))", "((2 (x -> ((2 (get x))))))"),
            ("2 x (2 x)", "((2 x -> ((2 (get x)))))"),
            ("2 x (2 x) A", "((2 x -> ((2 (get x))) A))"),
            ("2 (2 A) B", "((2 ((2 A)) B))"),
        ]
        checkParseExpression(cases)
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
            ("(x (Add x)) 3 4", (.integer(7), "")),
            ("x Multiply (Add x 3) 4 7", (.integer((3 + 7)*4), "")),
        ]
        check(cases)
    }

    func testLazy() {
        let cases: [(String, (PolCalValue, String))] = [
            // Equal :: A -> B -> Boolean -> X -> Y should only evaluate
            // either X or Y
            ("Equal 0 1 Print 1 Print 2", (.integer(2), "2")),
            ("True Print 1 Print 2", (.integer(1), "1")),
            // thunk version
            ("Equal 0 1 x Print 1 x Print 2 0", (.integer(2), "2")),
            // make sure it's not just lazy because of application order
            ("(consequent alternative condition (condition consequent alternative)) (Print 1) (Print 2) (True)", (.integer(1), "1")),
        ]
        check(cases)
    }

    func testFact() {
        let cases: [(String, (PolCalValue, String))] = [
            // this is thunked and will work
            ("(fact (fact fact)) (fact x (= 0 x z 1 (z * x (fact fact (- 1 x))) 99)) 5",
                (.integer(5*4*3*2*1), "")),
            // this will not halt until laziness is implemented properly
            ("(fact (fact fact)) (fact x (= 0 x 1 (* x (fact fact (- 1 Print x))))) 5",
                (.integer(5*4*3*2*1), ""))
        ]
        check(cases)
    }

    /* func testAckerman() {
        let True = standardLibrary["True"]!
        let ack1 = "(A (A A) A m n Print ((Equal m 0 (y + n 1) (x A A - 1 m (Equal n 0 1 (A A m - 1 n)))) 0)) 3 3"
        let parsed = Expression.topLevel(resolveSymbols(tokenize(ack1), library: standardLibrary)).string
        XCTAssertEqual(parsed, "(((A ((A)(A)) A -> (m -> (n -> ((Equal)(m)(0))(y -> ((Add)(get n)(1)))(x -> ((A)(A)((Sub)(1)(m))((Equal)(get n)(0)((A)(A)(m)((Sub)(1)(n))))))(0) (3)(3)")
        let cases: [(String, (PolCalValue, String))] = [
            // This one doesn't fully apply A so that eager evaluation works
            (ack1, (.integer(61), "")),
            // This one requires the boolean functions to be lazy
            ("(((A A A) A m n Equal m 0 + n 1 (A A - 1 m Equal n 0 1 (A A m - 1 n))) 3 3)", (.integer(61), "")),
        ]
        check(cases)
    }*/

}
