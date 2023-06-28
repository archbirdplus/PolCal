import Foundation

let standardLibrary: [String: PolCalValue] = [
    "1": .integer(1),
    "2": .integer(2),
    "3": .integer(3),
    "4": .integer(4),
    "5": .integer(5),
    "Add": .function(PolCalFunction(name: "Add", arity: 2) { v in
        guard case let .integer(x) = v else { precondition(false) }
        return .function(PolCalFunction(name: "(Add \(x))", arity: 1) { v in
            guard case let .integer(y) = v else { precondition(false) }
            return .integer(x + y)
        })
    }),
    "Multiply": .function(PolCalFunction(name: "Multiply", arity: 2) { v in
        guard case let .integer(x) = v else { precondition(false) }
        return .function(PolCalFunction(name: "(Multiply \(x)", arity: 1) { v in
            guard case let .integer(y) = v else { precondition(false) }
            return .integer(x * y)
        })
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
        return Expression(string: String(describing: x)) { x }
    }
    // preumably application-stoppers such as <closing paren> get checked here
    let values = (0..<f.arity).map { _ in nextExpression(&iterator) }
    return Expression(
        string: "\(f.name)(\(values.map { v in v.string }.joined(separator: ", ")))"
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
        .map { tok in library[tok] }
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
    print(expression.string)
    let value = expression.thunk()
    if case let .function(f) = value {
        return f.apply(.integer(69)) // give input here?
    }
    return value
}

