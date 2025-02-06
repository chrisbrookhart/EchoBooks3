//
//  Sentence.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/5/25.
//


//
//  Sentence.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
//  This model represents a sentence within a paragraph.
//  It includes a globalSentenceIndex for navigation purposes and uses a dictionary keyed by LanguageCode
//  to store the text and audio filename for each language.
//
 
import Foundation
import SwiftData

@Model
final class Sentence: Identifiable, Hashable, Decodable, Validatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the sentence (maps from JSON "sentenceID")
    var id: UUID
    
    /// The sequential index of the sentence within its paragraph.
    var sentenceIndex: Int
    
    /// A global sentence index, continuous throughout the entire book.
    var globalSentenceIndex: Int
    
    /// The reference string (e.g., scripture reference). May be empty.
    var reference: String
    
    /// A dictionary mapping each language to its sentence text.
    var text: [LanguageCode: String]
    
    /// A dictionary mapping each language to the corresponding audio filename.
    var audioFiles: [LanguageCode: String]?
    
    // MARK: - Relationships
    
    /// The parent Paragraph. (May be set later by SwiftData.)
    @Relationship var paragraph: Paragraph?
    
    // MARK: - Coding Keys
    // Note: For decoding from a language-specific JSON file, we assume the JSON contains a single language's text and audioFile.
    // You may need to merge data from different language files externally.
    enum CodingKeys: String, CodingKey {
        case id = "sentenceID"
        case sentenceIndex
        case globalSentenceIndex
        case reference
        case text
        case audioFile
    }
    
    // MARK: - Decodable Initializer
    // For the purpose of decoding a language-specific JSON file, we'll decode the text and audioFile for one language,
    // then initialize the dictionaries with that single language entry.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.sentenceIndex = try container.decode(Int.self, forKey: .sentenceIndex)
        self.globalSentenceIndex = try container.decode(Int.self, forKey: .globalSentenceIndex)
        self.reference = try container.decode(String.self, forKey: .reference)
        
        // For this decoding pass, we decode the text and audioFile for one language.
        // In a complete implementation, you might merge multiple language files.
        let languageText = try container.decode(String.self, forKey: .text)
        let languageCodeString = (decoder.userInfo[.languageCodeKey] as? String) ?? "en-US"
        guard let languageCode = LanguageCode(rawValue: languageCodeString) else {
            throw DecodingError.dataCorruptedError(forKey: .text,
                                                   in: container,
                                                   debugDescription: "Invalid language code.")
        }
        self.text = [languageCode: languageText]
        if let audioFileValue = try container.decodeIfPresent(String.self, forKey: .audioFile) {
            self.audioFiles = [languageCode: audioFileValue]
        } else {
            self.audioFiles = nil
        }
        
        self.paragraph = nil
    }
    
    // MARK: - Designated Initializer
    init(
        id: UUID = UUID(),
        sentenceIndex: Int,
        globalSentenceIndex: Int,
        reference: String,
        text: [LanguageCode: String],
        audioFiles: [LanguageCode: String]? = nil,
        paragraph: Paragraph? = nil
    ) {
        self.id = id
        self.sentenceIndex = sentenceIndex
        self.globalSentenceIndex = globalSentenceIndex
        self.reference = reference
        self.text = text
        self.audioFiles = audioFiles
        self.paragraph = paragraph
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: Sentence, rhs: Sentence) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Validatable
    
    func validate(with languages: [LanguageCode]) throws {
        // Ensure that for each language requested, there is text.
        for language in languages {
            if text[language] == nil {
                throw ValidationError.missingText(language: language)
            }
            if let audioFiles = audioFiles, audioFiles[language] == nil {
                throw ValidationError.missingAudioFile(language: language)
            }
        }
        
        // Also check that the sentence is associated with a paragraph.
        if paragraph == nil {
            throw ValidationError.missingSentence(paragraphID: UUID()) // or a more specific error if available
        }
    }
}
