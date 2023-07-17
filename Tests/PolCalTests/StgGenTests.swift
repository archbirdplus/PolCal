import XCTest
@testable import PolCalRuntime

// As these tests are highly specific to the optimizations made, it may
// be fine to adjust the tests later as new optimizations are developed.

func globalNameOf(_ f: Fun<SwiftInterpreted>) -> GlobalName? {
    if case let .global(x) = f.name { return x } else { return nil }
}

final class StgGenTests: XCTestCase {

    let pAdd = ParseNode.name(Add.name)
    let pOne = ParseNode.name(one.name)
    let pTwo = ParseNode.name(two.name)

    let funs = [
        globalNameOf(Add)!: Add,
        globalNameOf(True)!: True,
        globalNameOf(one)!: one,
        globalNameOf(two)!: two,
    ]

    func checkGen(_ node: ParseNode, _ cells: [StgCell]) {
        let table = StgTable()
        let _ = stgGen(table: table, funs: funs, scope: [], node)
        XCTAssertEqual(table.cells.count, cells.count)
        zip(table.cells, cells).enumerated().forEach { pair in
            let (n, (a, b)) = pair
            XCTAssertEqual(a.data, b.data, "data [\(n)]")
            XCTAssertEqual(a.arity, b.arity, "arity [\(n)]")
            XCTAssertEqual(a.args, b.args, "args [\(n)]")
        }
    }

    func testBasicAddition() {
        // do some basic sanity checks
        checkGen(
            .apply([.name(Add.name), .name(one.name), .name(two.name)]),
            [
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: []),
                StgCell(thunk: Ret, data: PolCalValue.integer(1), arity: 0, args: []),
                StgCell(thunk: Ret, data: PolCalValue.integer(2), arity: 0, args: []),
                // note: these two applications are currently fused into one
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [1, 2]),
            ]
        )
    }

    func testCalculatedArity() {
        // ((Add 1 2) 1)
        // ((Add 1) 2 1)
        // NOTE: there are bigger fish to fry but very related to this problem, see stgGen.swift#L36
        // assertion: second-level cells should have arity 0, not -1
        //          : Adds should have arity: 2, while their enclosing
        //            cells should have 0 and 1 respectively
        // note: literal cells are repeated, despite storing the same values
        /* expected cells:
            [ 0] = Add
            [ 1] = 1
            [ 2] = 2
            [ 3] = Add 1 2
            [ 4] = 1
            [ 5] = (Add 1 2) 1
            [ 6] = Add
            [ 7] = 1
            [ 8] = Add 1
            [ 9] = 2
            [10] = 1
            [11] = (Add 1) 2 1
            [12] = ((Add 1 2) 1) ((Add 1) 2 1)
            // although the form looks more like this: (Add 1 2 1 (Add 1 2 3))
        */
        var Apply = Ret // same but different (since it's not testable anyways)
        checkGen(
            .apply([.apply([.apply([pAdd, pOne, pTwo]), pOne]),
                    .apply([.apply([pAdd, pOne]), pTwo, pOne])]),
            [
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: []), // 0
                StgCell(thunk: Ret, data: PolCalValue.integer(1), arity: 0, args: []), // 1
                StgCell(thunk: Ret, data: PolCalValue.integer(2), arity: 0, args: []), // 2
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [1, 2]), // 3
                StgCell(thunk: Ret, data: PolCalValue.integer(1), arity: 0, args: []), // 4
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [1, 2, 4]), // 5
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: []), // 6
                StgCell(thunk: Ret, data: PolCalValue.integer(1), arity: 0, args: []), // 7
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [7]), // 8
                StgCell(thunk: Ret, data: PolCalValue.integer(2), arity: 0, args: []), // 9
                StgCell(thunk: Ret, data: PolCalValue.integer(1), arity: 0, args: []), // 10
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [7, 9, 10]), // 11
                StgCell(thunk: Add.code.thunk, data: nil, arity: 2, args: [1, 2, 11]), // 5
            ]
        )
    }

    // TODO: lambda + closure tests

}
