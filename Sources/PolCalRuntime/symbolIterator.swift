
struct SymbolIterator {
    var pointer: Int = 0
    var elements: [Symbol]

    init(_ elements: [Symbol]) {
        self.elements = elements
    }

    mutating func next() -> Symbol? {
        guard pointer >= 0 && pointer < elements.count else { return nil }
        let v = elements[pointer]
        pointer += 1
        return v
    }

    mutating func nextNotCloseParen() -> Symbol? {
        guard pointer >= 0 && pointer < elements.count else { return nil }
        let v = elements[pointer]
        if case .closeParen = v { return nil }
        pointer += 1
        return v
    }

    mutating func consumeParen() -> Bool {
        guard pointer >= 0 && pointer < elements.count else { return false }
        let v = elements[pointer]
        guard case .closeParen = v else { return false }
        pointer += 1
        return true
    }
}

