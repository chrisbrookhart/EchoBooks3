//
//  Chapter.swift
//
//  Updated to support decoding from unified structure JSON. If the "language" key is missing,
//  it defaults to .enUS. Extra keys like "totalParagraphs", "totalSentences", and "contentReferences"
//  are ignored.
//

import Foundation
import SwiftData

@Model
final class Chapter: Identifiable, Hashable, Decodable, Validatable {
    
    var id: UUID
    var language: LanguageCode
    var chapterNumber: Int
    var chapterTitle: String
    var paragraphs: [Paragraph]
    
    enum CodingKeys: String, CodingKey {
        case id = "chapterID"
        case language
        case chapterNumber
        case chapterTitle
        case paragraphs
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.chapterNumber = try container.decode(Int.self, forKey: .chapterNumber)
        self.chapterTitle = try container.decode(String.self, forKey: .chapterTitle)
        // If the language key is missing, default to .enUS.
        self.language = try container.decodeIfPresent(LanguageCode.self, forKey: .language) ?? .enUS
        // If paragraphs are missing, default to an empty array.
        self.paragraphs = try container.decodeIfPresent([Paragraph].self, forKey: .paragraphs) ?? []
    }
    
    init(
        id: UUID,
        language: LanguageCode,
        chapterNumber: Int,
        chapterTitle: String,
        paragraphs: [Paragraph] = []
    ) {
        self.id = id
        self.language = language
        self.chapterNumber = chapterNumber
        self.chapterTitle = chapterTitle
        self.paragraphs = paragraphs
    }
    
    func validate(with languages: [LanguageCode]) throws {
        // If no paragraphs exist, we assume this is a structure-level chapter.
        if paragraphs.isEmpty { return }
        for paragraph in paragraphs {
            try paragraph.validate(with: languages)
        }
    }
    
    static func == (lhs: Chapter, rhs: Chapter) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
