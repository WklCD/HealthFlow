import Foundation

struct CSVEncoder {
    static func encode<T: Encodable>(_ items: [T]) throws -> String {
        guard let first = items.first else { return "" }
        let mirror = Mirror(reflecting: first)
        let headers = mirror.children.map { $0.label ?? "" }.joined(separator: ",")
        let rows = items.map { item -> String in
            let m = Mirror(reflecting: item)
            return m.children.map { child -> String in
                let value = "\(child.value)"
                if value.contains(",") || value.contains("\"") || value.contains("\n") {
                    return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                }
                return value
            }.joined(separator: ",")
        }
        return ([headers] + rows).joined(separator: "\n")
    }
}