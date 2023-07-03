
public typealias PolCalInt = Int

public enum ParseError: Error {
    case unresolved([String])
}

public enum Symbol {
    case value(PolCalValue)
    case argument(String)
    case openParen
    case closeParen
}

public enum Token {
    case word(String)
    case openParen
    case closeParen
}

// This implements the n-arity function. Currying is done automatically by
// BoundFunction.apply.
public struct PolCalFunction: Equatable {
    let name: String
    let arity: Int
    let apply: ([PolCalValue]) -> PolCalValue
    public init(name: String, arity: Int, apply: @escaping ([PolCalValue]) -> PolCalValue) {
        self.name = name
        self.arity = arity
        self.apply = apply
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name // I trust name collisions won't occur.
    }
}

public struct BoundFunction: Equatable {
    let base: PolCalFunction
    let args: [PolCalValue]

    var name: String {
        "(\(base.name)\(args.map { x in "(\(x.toString()))" }.joined()))"
    }
    var arity: Int { base.arity - args.count }

    init(_ f: PolCalFunction, args: [PolCalValue] = []) {
        self.base = f
        self.args = args
    }

    func apply(_ val: PolCalValue) -> PolCalValue {
        var tmp = args
        tmp.append(val)
        if tmp.count < base.arity {
            return .function(BoundFunction(base, args: tmp))
        } else {
            return base.apply(tmp)
        }
    }
}

public enum PolCalValue: Equatable {
    case none
    case integer(PolCalInt)
    case double(Double)
    case function(BoundFunction)

    var function: BoundFunction? {
        if case let .function(f) = self { return f }
        else { return nil }
    }

    public static func unbound(_ base: PolCalFunction) -> PolCalValue {
        return .function(BoundFunction(base))
    }

    func toString() -> String {
        switch self {
        case .none:
            return "none"
        case let .integer(x):
            return String(x)
        case let .double(x):
            return String(x)
        case let .function(x):
            return x.name
        }
    }
}

public struct Expression {
    let string: String
    let thunk: () -> PolCalValue
}

