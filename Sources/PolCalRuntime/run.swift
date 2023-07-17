
struct SwiftInterpreted: Language {
    struct Code {
        let thunk: (StgTable, inout StgCell) -> PolCalValue
    }
    static func ret() -> Code {
        Code { (_ table: StgTable, _ cell: inout StgCell) -> PolCalValue in
            return cell.data!
        }
    }
}

struct StgCell {
    var thunk: (StgTable, inout StgCell) -> PolCalValue // cell contains  self-modifying code
    var data: PolCalValue?
    var arity: Int
    var args: [Int] = []

    var arityLeft: Int { arity - args.count }
}

class StgTable {
    var cells: [StgCell]

    init() {
        cells = []
    }

    @discardableResult func append(_ cell: StgCell) -> Int {
        let i = cells.count
        cells.append(cell)
        return i
    }
    subscript(i: Int) -> StgCell {
        get { cells[i] }
        set(v) { cells[i] = v }
    }
    func apply(_ i: Int, arg: Int) -> Int {
        var tmp = cells[i]
        // TODO: if we exceed the arity then create another cell pointing back
        tmp.args.append(arg)
        return append(tmp)
    }
    func thunk(_ i: Int) -> PolCalValue {
        cells[i].thunk(self, &cells[i])
    }
}

// also, add closure fun -> stgcell because closures are user-defined and
// so can't be lumped with the other funs

func addGlobalCells(_ funs: [Fun<SwiftInterpreted>], _ table: StgTable) {
// , _ litFuns: [LiteralFun], _ closureFuns: [ClosureFun]) {
    funs.forEach { fun in
        table.append(
            StgCell(
                thunk: fun.code.thunk,
                data: fun.data,
                arity: fun.syntax.arity
            )
        )
    }
}

func run(_ table: StgTable, entry: Int) -> PolCalValue {
    // currently ignoring unsaturated programs
    table[entry].thunk(table, &table[entry])
}

