
extension Expression {
    static func topLevel(_ symbols: [Symbol]) -> Expression {
        var iterator = symbols.makeIterator()
        return .parenthetical(&iterator)
    }

    static func parenthetical(_ symbols: inout IndexingIterator<[Symbol]>) -> Expression {
        var list: [Expression] = []
        while let node = Self.node(&symbols) {
            list.append(node)
        }
        return Expression(
            string: "(\(list.map { v in "(\(v.string))" }.joined()))"
        ) {
            return list.suffix(list.count-1).reduce(list.first.map { $0.thunk() } ?? .none) { r, x in r.function!.apply(x.thunk()) }
        }
    }

    static func node(_ symbols: inout IndexingIterator<[Symbol]>) -> Expression? {
        let top = symbols.next()
        switch top {
        case let .value(v):
            // keep applying until arity=0
            if let f = v.function {
                var list: [Expression] = []
                for _ in 0..<f.arity {
                    // TODO: check top.isOperator for currying operators
                    guard let u = Self.node(&symbols) else { break }
                    list.append(u)
                }
                return Expression(
                    string: "(\(v.toString()))(\(list.map { v in "(\(v.string))" }.joined()))"
                ) {
                    // TODO: de-thunking should be moved inside the function spec
                    // NOTE: force-unwrapping is safe here because the function
                    // arity is never exceeded
                    return list.reduce(v) { r, x in r.function!.apply(x.thunk()) }
                }
            } else {
                return Expression(string: "(\(v.toString()))") { v }
            }
        case let .argument(name):
            fatalError("closures not implemented")
        case .openParen:
            return .parenthetical(&symbols)
        case .closeParen, .none:
            return nil
        }
    }
}

