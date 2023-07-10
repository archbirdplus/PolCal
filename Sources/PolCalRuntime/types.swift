
public typealias PolCalInt = Int

public struct GlobalName {
    public let i: Int
    public let str: String
}
public typealias ArgumentName = GlobalName // same thing but different

public enum Name {
    case global(GlobalName)
    case argument(ArgumentName)

    public var str: String {
        switch self {
        case let .global(x):
            return x.str
        case let .argument(x):
            return x.str
        }
    }
}

public struct SyntaxStyle {
    public let name: Name
    public let arity: Int
}

public protocol Language {
    associatedtype Code
}

struct LiteralFun {
    let name: Name
    let literal: PolCalValue

    init(_ name: Name, _ literal: PolCalValue) {
        self.name = name
        self.literal = literal
    }
}

public struct Fun<L: Language> {
    let name: Name
    let syntax: SyntaxStyle
    let code: L.Code

    init(syntax: SyntaxStyle, code: L.Code) {
        name = syntax.name
        self.syntax = syntax
        self.code = code
    }
}

public indirect enum ParseNode: CustomDebugStringConvertible {
    case name(Name) // for now, numbers will be thunked as () -> Int
    case apply([ParseNode])
    case closure(ArgumentName, ParseNode)

    public var debugDescription: String {
        switch self {
        case let .name(name):
            return name.str
        case let .apply(nodes):
            return "[\(nodes.map { n in n.debugDescription }.joined(separator: " "))]"
        case let .closure(x, node):
            return "\(x.str) -> \(node.debugDescription)"
        }
    }
}

public enum Symbol {
    case value(SyntaxStyle)
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
        args.isEmpty ?
            base.name :
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

public enum PolCalValue: Equatable, CustomDebugStringConvertible {
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

    public var debugDescription: String { toString() }
}

public struct Expression {
    let string: String
    let thunk: ([(String, PolCalValue)]) -> PolCalValue
}

