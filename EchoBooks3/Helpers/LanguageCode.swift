//
//  LanguageCode.swift

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
        case .enUS: return "English"
        case .esES: return "Spanish"
        case .frFR: return "French"
        case .deDE: return "German"
        case .jaJP: return "Japanese"
        case .zhCN: return "Mandarin"
        case .tlPH: return "Tagalog"
        }
    }
}


