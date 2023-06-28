
public typealias PolCalInt = Int

public struct PolCalFunction {
    let name: String
    let arity: Int
    let apply: (PolCalValue) -> PolCalValue
    public init(name: String, arity: Int, apply: @escaping (PolCalValue) -> PolCalValue) {
        self.name = name
        self.arity = arity
        self.apply = apply
    }
}

public enum PolCalValue {
    case none
    case integer(PolCalInt)
    case double(Double)
    case function(PolCalFunction)
}

public struct Expression {
    let string: String
    let thunk: () -> PolCalValue
}

