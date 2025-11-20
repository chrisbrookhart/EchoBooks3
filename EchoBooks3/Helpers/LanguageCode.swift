//
//  LanguageCode.swift
//
//

import Foundation

enum LanguageCode: String, Codable, CaseIterable, Hashable, Identifiable {
    // Full locale codes (existing)
    case enUS = "en-US"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case deDE = "de-DE"
    case jaJP = "ja-JP"
    case zhCN = "zh-CN"
    case tlPH = "tl-PH"
    case ptBR = "pt-BR"
    
    // Simplified codes (new format support)
    case en = "en"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case ja = "ja"
    case zh = "zh"
    case tl = "tl"
    case pt = "pt"
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .enUS, .en: return "English"
        case .esES, .es: return "Spanish"
        case .frFR, .fr: return "French"
        case .deDE, .de: return "German"
        case .jaJP, .ja: return "Japanese"
        case .zhCN, .zh: return "Mandarin"
        case .tlPH, .tl: return "Tagalog"
        case .ptBR, .pt: return "Portuguese"
        }
    }
    
    /// Maps a language code string (simplified or full) to a LanguageCode enum value.
    /// - Parameter code: A language code string (e.g., "en", "en-US", "es", "es-ES")
    /// - Returns: The corresponding LanguageCode, or nil if not found
    static func fromCode(_ code: String) -> LanguageCode? {
        // First, try direct match (handles both simplified and full codes)
        if let lang = LanguageCode(rawValue: code) {
            return lang
        }
        
        // Map simplified codes to full codes for backward compatibility
        switch code.lowercased() {
        case "en":
            return .enUS
        case "es":
            return .esES
        case "fr":
            return .frFR
        case "de":
            return .deDE
        case "ja":
            return .jaJP
        case "zh":
            return .zhCN
        case "tl":
            return .tlPH
        case "pt":
            return .ptBR
        default:
            return nil
        }
    }
    
    /// Returns the full locale code version of this language code.
    /// Simplified codes (en, es, fr) are converted to their full equivalents (en-US, es-ES, fr-FR).
    /// Full codes are returned as-is.
    var fullCode: String {
        switch self {
        case .en: return "en-US"
        case .es: return "es-ES"
        case .fr: return "fr-FR"
        case .de: return "de-DE"
        case .ja: return "ja-JP"
        case .zh: return "zh-CN"
        case .tl: return "tl-PH"
        case .pt: return "pt-BR"
        case .enUS: return "en-US"
        case .esES: return "es-ES"
        case .frFR: return "fr-FR"
        case .deDE: return "de-DE"
        case .jaJP: return "ja-JP"
        case .zhCN: return "zh-CN"
        case .tlPH: return "tl-PH"
        case .ptBR: return "pt-BR"
        }
    }
}
