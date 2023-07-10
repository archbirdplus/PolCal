import Foundation

func tokenize(_ string: String) -> [Token] {
    var tokens: [Token] = []
    var tmp = ""
    for char in string {
        // TODO: array brackets would be parsed here
        switch char {
        case " ", "\n":
            tokens.append(.word(tmp))
            tmp = ""
        case "(":
            tokens.append(.word(tmp))
            tokens.append(.openParen)
            tmp = ""
        case ")":
            tokens.append(.word(tmp))
            tokens.append(.closeParen)
            tmp = ""
        default:
            tmp.append(char)
        }
    }
    tokens.append(.word(tmp))
    return tokens.filter { x in
        if case let .word(str) = x { return str != "" } else { return true }
    }
}

func resolveSymbols(_ tokens: [Token], syntaxes: [String: SyntaxStyle]) -> ([LiteralFun], [Symbol]) {
    var litFuns: [LiteralFun] = []
    let symbols: [Symbol] = tokens.map { tok in
        switch tok {
        case let .word(name):
            if let v = syntaxes[name] { return .value(v) }
            if let v = Int(name).map(PolCalValue.integer) ??
                Double(name).map(PolCalValue.double) {
                let name = Name.global(GlobalName(i: litFuns.count, str: name))
                litFuns.append(LiteralFun(name, v))
                return .value(SyntaxStyle(name: name, arity: 0))
            }
            return .argument(name)
        case .openParen:
            return .openParen
        case .closeParen:
            return .closeParen
        }
    }
    return (litFuns, symbols)
}

/*
func topLevelExpression(_ symbols: [String], library: [String: PolCalValue]) -> Expression {
    let funcs = tokens
        .map { tok in
            library[tok] ??
            Int(tok).map(PolCalValue.integer) ??
            Double(tok).map(PolCalValue.double)
        }
        .prefix { x in x != nil }
        .compactMap { x in x }
    var iterator = funcs.makeIterator()
    return nextExpression(&iterator)
}

func nextExpression(_ iterator: inout IndexingIterator<[PolCalValue]>) -> Expression {
    let x = iterator.next()! // what to do? the parent function needs to be curried for such a premature end
    guard case let .function(f) = x else {
        return Expression(string: x.toString()) { x }
    }
    // preumably application-stoppers such as <closing paren> get checked here
    let values = (0..<f.arity).map { _ in nextExpression(&iterator) }
    return Expression(
        string: "\(f.name)\(values.map { v in "(\(v.string))" }.joined())"
    ) {
        values.reduce(x) { r, v in
            guard case let .function(f) = r else { precondition(false) }
            // check arity??
            return f.apply(v.thunk()) // this is where the laziness is failed
        }
    }
}
*/

/*
// TODO: may need to throw if parse errors can physically occur
public func execute(_ string: String, api: [String: PolCalValue]) -> PolCalValue {
    let tokens = tokenize(string)
    // custom API may override standard library
    let library = standardLibrary.merging(api) { (_, new) in new }
    let symbols = resolveSymbols(tokens, library: library)
    // let expression = prepareComputation(tokens, library: library)
    let expression = Expression.topLevel(symbols)
    let value = expression.thunk([])
    // if value is a function, the user may choose to pass arguments to it
    return value
}
*/

