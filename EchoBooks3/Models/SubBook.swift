//
//  SubBook.swift
//
//  This model represents a subbook within a Book. For flat books, this will be the default subbook.
//  A SubBook contains an array of Chapter objects.
//
 
import Foundation
import SwiftData

@Model
final class SubBook: Identifiable, Hashable, Decodable, Validatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the subbook (maps from JSON "subBookID")
    var id: UUID
    
    /// The number representing the subbook's order.
    var subBookNumber: Int
    
    /// The title of the subbook.
    var subBookTitle: String
    
    // MARK: - Relationships
    
    /// The parent Book. (May be set later by SwiftData.)
    @Relationship var book: Book?
    
    /// An array of Chapters in this subbook.
    @Relationship var chapters: [Chapter]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id = "subBookID"
        case subBookNumber
        case subBookTitle
        case chapters
    }
    
    // MARK: - Decodable Initializer
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.subBookNumber = try container.decode(Int.self, forKey: .subBookNumber)
        self.subBookTitle = try container.decode(String.self, forKey: .subBookTitle)
        self.chapters = try container.decodeIfPresent([Chapter].self, forKey: .chapters) ?? []
        self.book = nil
    }
    
    // MARK: - Designated Initializer
    
    init(
        id: UUID = UUID(),
        subBookNumber: Int,
        subBookTitle: String,
        chapters: [Chapter] = [],
        book: Book? = nil
    ) {
        self.id = id
        self.subBookNumber = subBookNumber
        self.subBookTitle = subBookTitle
        self.chapters = chapters
        self.book = book
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: SubBook, rhs: SubBook) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Validatable
    
    func validate(with languages: [LanguageCode]) throws {
        // Ensure that there is at least one chapter.
        if chapters.isEmpty {
            throw ValidationError.missingChapters(subBookID: id)
        }
        for chapter in chapters {
            try chapter.validate(with: languages)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the chapters sorted by chapterNumber.
    var sortedChapters: [Chapter] {
        chapters.sorted { $0.chapterNumber < $1.chapterNumber }
    }
}
