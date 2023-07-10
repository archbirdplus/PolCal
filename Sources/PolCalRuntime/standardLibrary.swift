
let True = PolCalFunction(name: "True", arity: 2) { v in return v[0] }
let False = PolCalFunction(name: "False", arity: 2) { v in return v[1] }

let functions = [
    PolCalFunction(name: "Add", arity: 2) { args in
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
            fatalError("Not addable values: \(args[0]) \(args[1])")
        }
    },
    PolCalFunction(name: "Sub", arity: 2) { args in
        switch (args[0], args[1]) {
        case let (.integer(x), .integer(y)):
            return .integer(y - x)
        case let (.double(x), .double(y)):
            return .double(y - x)
        case let (.double(x), .integer(y)):
            return .double(Double(y) - x)
        case let (.integer(x), .double(y)):
            return .double(y - Double(x))
        default:
            fatalError("Sub unsubbable \(args[0]) \(args[1])")
        }
    },
    PolCalFunction(name: "Multiply", arity: 2) { args in
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
            impostor()
            fatalError("Multiplication failed due to types \(args[0]) * \(args[1])")
        }
    },
    True,
    False,
    PolCalFunction(name: "Equal", arity: 2) { v in
        v[0] == v[1] ? .unbound(True) : .unbound(False)
    }
]

// oof
let standardLibrary = {
    var stdlib: [String: PolCalValue] = [:]
    functions.forEach { f in
        stdlib[f.name] = PolCalValue.unbound(f)
    }
    let aliases = [
        ("Add", "+"),
        ("Sub", "-"),
        ("Equal", "="),
        ("Multiply", "*")
    ]
    aliases.forEach { pair in
        stdlib[pair.1] = stdlib[pair.0]
    }
    return stdlib
}()

