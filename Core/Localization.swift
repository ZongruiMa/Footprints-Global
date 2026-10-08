import Foundation

enum AppLanguage {
    static let codes = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "fr", "de", "es", "pt", "ar"]
    static let names = ["English", "简体中文", "繁體中文", "日本語", "한국어", "Français", "Deutsch", "Español", "Português", "العربية"]
    static func resolve(_ preferences: [String]) -> String {
        for tag in preferences {
            if tag.hasPrefix("zh") {
                return tag.contains("Hant") || tag.contains("TW") || tag.contains("HK") ? "zh-Hant" : "zh-Hans"
            }
            if let code = codes.first(where: { tag == $0 || tag.hasPrefix($0 + "-") }) { return code }
        }
        return "en"
    }
    static var current: String {
        let saved = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "system"
        return codes.contains(saved) ? saved : resolve(Locale.preferredLanguages)
    }
    static let catalog: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "Translations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return table
    }()
    static func text(_ key: String, language: String, arguments: [String] = []) -> String {
        var result = catalog[key]?[language] ?? key
        for (i, value) in arguments.enumerated() { result = result.replacingOccurrences(of: "{\(i)}", with: value) }
        return result
    }
}
func L(_ key: String, _ arguments: String...) -> String {
    AppLanguage.text(key, language: AppLanguage.current, arguments: arguments)
}
