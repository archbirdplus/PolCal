import XCTest
@testable import PolCalRuntime

let Ret = SwiftInterpreted.Code
    { table, cell in cell.data! }
    .thunk

let Add = Fun<SwiftInterpreted>(
    syntax: SyntaxStyle(
        name: .global(GlobalName(i: 0, str: "Add")),
        arity: 2
    ),
    code: SwiftInterpreted.Code
    { (table: StgTable, cell: inout StgCell) -> PolCalValue in
        guard case let .integer(x) = table.thunk(cell.args[0]) else
            { return .none }
        guard case let .integer(y) = table.thunk(cell.args[1]) else
            { return .none }
        cell.data = .integer(x + y)
        cell.thunk = Ret
        return cell.data!
    })

let True = Fun<SwiftInterpreted>(
    syntax: SyntaxStyle(
        name: .global(GlobalName(i: 0, str: "True")),
        arity: 2
    ),
    code: SwiftInterpreted.Code
    { table, cell in
        cell.data = table.thunk(cell.args[0])
        cell.thunk = Ret
        return cell.data!
    }
)

let one = Fun<SwiftInterpreted>(LiteralFun(name: .global(GlobalName(i: 1, str: "1")), literal: .integer(1)))
let two = Fun<SwiftInterpreted>(LiteralFun(name: .global(GlobalName(i: 2, str: "2")), literal: .integer(2)))

final class InterpretedStgRuntimeTests: XCTestCase {

    func testBasicAdd() {
        // "+ 1 2"
        // i ; F    data    arity   args
        // --------- STG setup ----------
        // 0 = Add  nil     2       []
        // 1 = ret  int:1   0       []
        // 2 = ret  int:2   0       []
        // ----- applying arguments -----
        // 3 = Add  nil     2       [1]
        // 4 = Add  nil     2       [1,2]
        // ---- after forcing thunks ----
        // 4 = ret  int:3   2       [1,2]
        let table = StgTable()
        addGlobalCells([Add], table) // insert add at 0
        addGlobalCells([one, two], table) // insert 1, 2 at 1, 2
        XCTAssertEqual(table[0].data, nil)
        XCTAssertEqual(one.data, PolCalValue.integer(1))
        XCTAssertEqual(two.data, PolCalValue.integer(2))
        XCTAssertEqual(table[1].data, PolCalValue.integer(1))
        XCTAssertEqual(table[2].data, PolCalValue.integer(2))
        // simulate a closure applying arguments, wiring the cells together
        let add1i = table.apply(0, arg: 1)
        let add12i = table.apply(add1i, arg: 2)
        // run will force the necessary thunks
        let val = PolCalRuntime.run(table, entry: add12i)
        XCTAssertEqual(val, .integer(3))
        // imagine if we could check table[add12i].thunk === SwiftInterpreted.ret
        XCTAssertEqual(table[add12i].data, PolCalValue.integer(3))
        XCTAssertEqual(table[add12i].arity, 2)
        XCTAssertEqual(table[add12i].args, [1, 2])
        XCTAssertEqual(table.cells.count, 5)
    }

    func testReturnFirst() {
        let table = StgTable()
        addGlobalCells([True], table)
        addGlobalCells([one, two], table)
        // simulate application: "True 1 2"
        let i = table.apply(0, arg: 1)
        let j = table.apply(i, arg: 2)
        let val = PolCalRuntime.run(table, entry: j)
        XCTAssertEqual(val, .integer(1))
        XCTAssertEqual(table[1].data, PolCalValue.integer(1))
        XCTAssertEqual(table[2].data, PolCalValue.integer(2))
        XCTAssertEqual(table[j].arity, 2)
        XCTAssertEqual(table[j].args, [1, 2])
        XCTAssertEqual(table[i].arity, 2)
        XCTAssertEqual(table[0].arity, 2)
        XCTAssertEqual(i, 3)
        XCTAssertEqual(j, 4)
        XCTAssertEqual(table.cells.count, 5) // True, 1, 2, True 1, True 2
    }

}
