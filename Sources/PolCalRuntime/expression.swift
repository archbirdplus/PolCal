
func impostor() { }

/*
extension Expression {
    static func topLevel(_ symbols: [Symbol]) -> Expression {
        var iterator = SymbolIterator(symbols)
        return .parenthetical(&iterator, [])
    }

    static func parenthetical(_ symbols: inout SymbolIterator, _ scope: [String]) -> Expression {
        var list: [Expression] = []
        while let node = Self.node(&symbols, scope) {
            list.append(node)
        }
        // A node terminated by a parenthesis will have the paren consume here.
        // Nothing will happen if the node is terminated by the end of the file.
        symbols.consumeParen()
        return Expression(
            string: "(\(list.map { v in "\(v.string)" }.joined(separator: " ")))"
        ) { scope in
            return list.suffix(list.count-1).reduce(list.first.map { $0.thunk(scope) } ?? .none) { r, x in r.function?.apply(x.thunk(scope)) ?? { print(r); return x.thunk(scope) }() }
        }
    }

    static func node(_ symbols: inout SymbolIterator, _ scope: [String]) -> Expression? {
        let top = symbols.nextNotCloseParen()
        switch top {
        case let .value(v):
            // keep applying until arity=0
            if let f = v.function {
                var list: [Expression] = []
                for _ in 0..<f.arity {
                    // TODO: check top.isOperator for currying operators
                    guard let u = Self.node(&symbols, scope) else { break }
                    list.append(u)
                }
                if !list.isEmpty {
                    return Expression(
                        string: "(\(v.toString()) \(list.map { v in "\(v.string)" }.joined(separator: " ")))"
                    ) { scope in
                        // TODO: de-thunking should be moved inside the function spec
                        // NOTE: force-unwrapping is safe here because the function
                        // arity is never exceeded
                        return list.reduce(v) { r, x in r.function!.apply(x.thunk(scope)) }
                    }
                }
            }
            return Expression(string: "\(v.toString())") { _ in v }
        case let .argument(name):
            if scope.contains(name) {
                return Expression(string: "(get \(name))")
                        { scope in scope.last { pair in pair.0 == name }!.1 }
                    
            }
            return Expression.closure(&symbols, name, scope)
        case .openParen:
            return .parenthetical(&symbols, scope)
        case .none:
            return nil
        case .closeParen:
            fatalError("Impossible closeParen")
        }
    }

    static func closure(_ symbols: inout SymbolIterator, _ name: String, _ scope: [String]) -> Expression {
        guard let node = Self.node(&symbols, scope + [name]) else {
            return Expression(string: "\(name) -> ()") { _ in .none }
        }
        let expName = "\(name) -> \(node.string)"
        return Expression(string: expName) { scope in
            PolCalValue.unbound(PolCalFunction(
                name: expName,
                arity: 1) { args in
                node.thunk(scope + [(name, args[0])])
            })
        }
    }
}
*/
