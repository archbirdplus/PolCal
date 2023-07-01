import Foundation

let standardLibrary: [String: PolCalValue] = [
    "Add": .unbound(PolCalFunction(name: "Add", arity: 2) { args in
        switch (args[0], args[1]) {
        case let (.integer(x), .integer(y)):
            return .integer(x + y)
        case let (.double(x), .double(y)):
            return .double(x + y)
        case let (.double(x), .integer(y)):
            return .double(x + Double(y))
        case let (.integer(x), .double(y)):
            return .double(Double(x) + y)
        default:
            precondition(false)
        }
    }),
    "Multiply": .unbound(PolCalFunction(name: "Multiply", arity: 2) { args in
        switch (args[0], args[1]) {
        case let (.integer(x), .integer(y)):
            return .integer(x * y)
        case let (.double(x), .double(y)):
            return .double(x * y)
        case let (.double(x), .integer(y)):
            return .double(x * Double(y))
        case let (.integer(x), .double(y)):
            return .double(Double(x) * y)
        default:
            precondition(false)
        }
    })
]

func tokenize(_ string: String) -> [String] {
    string
        .components(separatedBy: CharacterSet(charactersIn: " \n"))
        .filter { x in x != "" }
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

func prepareComputation(_ tokens: [String], library: [String: PolCalValue]) -> Expression {
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

public func execute(_ string: String, api: [String: PolCalValue]) -> PolCalValue {
    let tokens = tokenize(string)
    // custom API may override standard library
    let library = standardLibrary.merging(api) { (_, new) in new }
    let expression = prepareComputation(tokens, library: library)
    print("expression string: \(expression.string)")
    let value = expression.thunk()
    if case let .function(f) = value {
        return f.apply(.integer(69)) // give input here?
    }
    return value
}

