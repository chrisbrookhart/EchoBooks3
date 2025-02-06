//
//  Paragraph.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/5/25.
//


//
//  Paragraph.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
//  This model represents a paragraph within a chapter.
//  It contains an array of Sentence objects.
//
 
import Foundation
import SwiftData

@Model
final class Paragraph: Identifiable, Hashable, Decodable, Validatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the paragraph (maps from JSON "paragraphID")
    var id: UUID
    
    /// The sequential index of the paragraph within the chapter.
    var paragraphIndex: Int
    
    // MARK: - Relationships
    
    /// The parent Chapter. (May be set later by SwiftData.)
    @Relationship var chapter: Chapter?
    
    /// An array of Sentence objects in this paragraph.
    @Relationship var sentences: [Sentence]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id = "paragraphID"
        case paragraphIndex
        case sentences
    }
    
    // MARK: - Decodable Initializer
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.paragraphIndex = try container.decode(Int.self, forKey: .paragraphIndex)
        self.sentences = try container.decodeIfPresent([Sentence].self, forKey: .sentences) ?? []
        self.chapter = nil
    }
    
    // MARK: - Designated Initializer
    
    init(
        id: UUID = UUID(),
        paragraphIndex: Int,
        sentences: [Sentence] = [],
        chapter: Chapter? = nil
    ) {
        self.id = id
        self.paragraphIndex = paragraphIndex
        self.sentences = sentences
        self.chapter = chapter
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: Paragraph, rhs: Paragraph) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Validatable
    
    func validate(with languages: [LanguageCode]) throws {
        // Ensure that there is at least one sentence.
        if sentences.isEmpty {
            throw ValidationError.missingSentence(paragraphID: id)
        }
        for sentence in sentences {
            try sentence.validate(with: languages)
        }
    }
}
