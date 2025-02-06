//
//  LanguageCode.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
 
import Foundation

enum LanguageCode: String, Codable, CaseIterable, Hashable, Identifiable {
    case enUS = "en-US"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case deDE = "de-DE"
    case jaJP = "ja-JP"
    case zhCN = "zh-CN"
    case tlPH = "tl-PH"
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .enUS: return "English (US)"
        case .esES: return "Spanish (ES)"
        case .frFR: return "French (FR)"
        case .deDE: return "German (DE)"
        case .jaJP: return "Japanese (JP)"
        case .zhCN: return "Mandarin (CN)"
        case .tlPH: return "Tagalog (PH)"
        }
    }
}
