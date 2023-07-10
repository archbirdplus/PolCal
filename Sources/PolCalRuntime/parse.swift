
class Parser {
    var symbols: SymbolIterator

    var argId = 0
    func makeArgName(_ str: String) -> ArgumentName {
        let a = ArgumentName(i: argId, str: str)
        argId += 1
        return a
    }

    init(_ symbols: [Symbol]) {
        self.symbols = SymbolIterator(symbols)
    }

    func parse() -> ParseNode {
        let node = self.parenthetical(scope: [])
        let simplified = Self.simplify(node)
        return simplified
    }

    // simply cases of "a 1 a": "a -> [1 a]" rather than "a -> [[1 a]]"
    static func simplify(_ node: ParseNode) -> ParseNode {
        switch node {
        case .name:
            return node
        case let .apply(nodes):
            let tmp = nodes.map(Self.simplify)
            return tmp.count == 1 ? tmp[0] : .apply(tmp)
        case let .closure(name, parseNode):
            return .closure(name, Self.simplify(parseNode))
        }
    }

    func parenthetical(scope: [ArgumentName]) -> ParseNode {
        var list: [ParseNode] = []
        while let node = self.node(scope: scope) {
            list.append(node)
        }
        symbols.consumeParen()
        return .apply(list)
    }

    func node(scope: [ArgumentName]) -> ParseNode? {
        guard let top = symbols.nextNotCloseParen() else { return nil }
        switch top {
        case let .value(v):
            let arity = v.arity
            var list: [ParseNode] = [.name(v.name)]
            for _ in 0..<arity {
                guard let n = self.node(scope: scope) else { break }
                list.append(n)
            }
            return .apply(list)
        case let .argument(str):
            if let name = scope.last(where: { s in s.str == str }) {
                return .name(.argument(name))
            }
            let name = makeArgName(str)
            var next = scope
            next.append(name)
            return .closure(name, self.node(scope: next) ?? .apply([]))
        case .openParen:
            return self.parenthetical(scope: scope)
        default:
            fatalError("unreachable close paren in node")
        }
    }
}

func parse(_ symbols: [Symbol]) -> ParseNode {
    let p = Parser(symbols)
    return p.parse()
}
let parse = Parser.parse

