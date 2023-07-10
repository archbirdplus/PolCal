import Foundation
import PolCalRuntime

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Fatal error: no program to run.")
    exit(0)
}
var file = try! String(contentsOf: URL(fileURLWithPath: args[1]))

/*
print(PolCalRuntime.execute(file, api: [
    "Print": .unbound(PolCalFunction(name: "Print", arity: 1) { v in
        print(v)
        return v[0]
    }),
    // TODO: return read string once strings are implemented
    "Read": .unbound(PolCalFunction(name: "Read", arity: 0) { v in
        let _ = readLine()
        return .none
    }),
    "Error": .unbound(PolCalFunction(name: "Error", arity: 1) { v in
        print("[ERROR THROWN]", v)
        return .none
    }),
]))
*/
