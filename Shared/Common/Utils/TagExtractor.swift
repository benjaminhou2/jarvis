import Foundation

enum TagExtractor {
    static func extract(from text: String) -> [String] {
        // match #tag 字母数字与下划线、中文等，简单实现
        let pattern = "#([\\p{L}0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
        return matches.map { ns.substring(with: $0.range(at: 1)).lowercased() }
    }
}


