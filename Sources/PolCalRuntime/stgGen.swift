
func freeVariables(_ node: ParseNode) -> Set<ArgumentName> {
    switch node {
    case let .name(name):
        if case let .argument(argName) = name { return Set([argName]) }
        return []
    case let .apply(nodes):
        var set = Set<ArgumentName>()
        nodes.forEach { n in set.formUnion(freeVariables(n)) }
        return set
    case let .closure(argName, n):
        var set = freeVariables(n)
        set.remove(argName)
        return set
    }
}

func stgGen(table: StgTable, funs: [GlobalName: Fun<SwiftInterpreted>], scope: [ArgumentName], _ node: ParseNode) -> Int {
    switch node {
    case let .name(name):
        if case let .global(globalName) = name {
            let fun = funs[globalName]!
            return table.append(StgCell(
                thunk: fun.code.thunk,
                data: fun.data,
                arity: fun.syntax.arity
            ))
        } else {
            // maybe, the caller should just read their own env...
            return table.append(StgCell(
                thunk: { _, cell in .integer(cell.args[0]) },
                arity: 1
            ))
        }

// MARK: NOTE: TODO: the following .apply([nodes]) -> stg conversion code is very scuffed. there are two conflicting stratagies being used simultaneously. one of them must be removed
// strat A: (Add 1 2) turns into Cell(Add, [1, 2])
// strat B: (Add 1 2) turns into Cell(Apply, [0, 1, 2])
// strat A is slightly more efficient but breaks down for complicated expressions like (Add 1 2 3). it needs to explicitly chunk arguments up into (Add 1 2)(3) to prevent the over-application of Add
// strat B is more general, but less efficient. if takes the strat for arguments from A, that [0] := Add, then Cell(Apply, [0, ...]). it doesn't need to worry about chunking though because chunking is handled dynamically (and then arity is known and never exceeded)



    case let .apply(nodes):
        if nodes.isEmpty {
            return table.append(StgCell(
                thunk: { _, _ in PolCalValue.none },
                arity: 0
            ))
        }
        let lifted = nodes.map { arg in
            stgGen(table: table, funs: funs, scope: scope, arg)
        }
        // this thunk is hereby known as Apply
        return table.append(StgCell(
            thunk: { table, cell in
                let bound = lifted
                    .enumerated()
                    .map { pair in
                        let (n, argCell) = pair
                        return scope.enumerated().filter { envIndexName in
                            freeVariables(nodes[n]).contains(envIndexName.1)
                        }.reduce(argCell) { callee, envIndexName in
                            table.apply(callee, arg: cell.args[envIndexName.0])
                        }
                    }
                let fin = bound
                    .dropFirst()
                    .reduce(bound[0]) { ret, cell in
                        table.apply(ret, arg: cell)
                    }
                return table.thunk(fin)
            },

            // um... there shouldn't be overapplied funs _ever_,
            // so applications need to be broken up, perhaps in
            // table.append (but then table needs to keep track
            // of args for automatic coalescing) e.g. Add 3 2 1
            // will probably throw away the 1

            // arity always remains from the parent function
            // if lifted[0] = (add 1) then ((add 1) 2) naturally has
            // arityLeft = 0 because args = [1, 2]
            arity: table[lifted[0]].arity,
            args: [Int](lifted.dropFirst())
        ))
    case let .closure(arg, node):
        var body = stgGen(table: table, funs: funs, scope: scope + [arg], node)
        return table.append(StgCell(
            thunk: { table, cell in
                return table.thunk(table.apply(body, arg: cell.args[0]))
            },
            arity: 0 // at least 0, but it probably doesn't make sense to expect more (because of literals)
        ))
    }
}

