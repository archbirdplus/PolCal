
public typealias PolCalInt = Int

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
        "(\(base) bound [\(args.map { x in "\(x)" }.joined(separator: ", "))])"
    }
    var arity: Int { base.arity - args.count }

    init(_ f: PolCalFunction, args: [PolCalValue] = []) {
        self.base = f
        self.args = args
    }

    func apply(_ val: PolCalValue) -> PolCalValue {
        var tmp = args
        tmp.append(val)
        if arity > 1 {
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

    public static func unbound(_ base: PolCalFunction) -> PolCalValue {
        return .function(BoundFunction(base))
    }
}

public struct Expression {
    let string: String
    let thunk: () -> PolCalValue
}

