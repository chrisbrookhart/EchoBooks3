//
//  Book.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
//  This model represents a book that uses the subbook concept exclusively.
//  Every book must have at least one subbook (for flat books, a "default" subbook).
//  Content for each language is stored separately and loaded lazily via SwiftData.
//
 
import Foundation
import SwiftData

@Model
final class Book: Identifiable, Hashable, Decodable, Validatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the book (maps from JSON "bookID")
    var id: UUID
    
    /// The title of the book.
    var bookTitle: String
    
    /// The author (or translator) of the book.
    var author: String
    
    /// The list of language codes in which the book is available.
    var languages: [LanguageCode]
    
    /// An optional description of the book.
    var bookDescription: String?
    
    /// The name of the cover image.
    var coverImageName: String
    
    /// A short code for the book (e.g., "BOOKM").
    var bookCode: String
    
    // MARK: - Relationships
    
    /// The subbooks in this book. Every book must have at least one.
    @Relationship var subBooks: [SubBook]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id = "bookID"
        case bookTitle
        case author
        case languages
        case bookDescription
        case coverImageName
        case bookCode
        case subBooks
    }
    
    // MARK: - Decodable Initializer
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.bookTitle = try container.decode(String.self, forKey: .bookTitle)
        self.author = try container.decode(String.self, forKey: .author)
        self.languages = try container.decode([LanguageCode].self, forKey: .languages)
        self.bookDescription = try container.decodeIfPresent(String.self, forKey: .bookDescription)
        self.coverImageName = try container.decode(String.self, forKey: .coverImageName)
        self.bookCode = try container.decode(String.self, forKey: .bookCode)
        self.subBooks = try container.decode([SubBook].self, forKey: .subBooks)
    }
    
    // MARK: - Designated Initializer
    
    init(
        id: UUID = UUID(),
        bookTitle: String,
        author: String,
        languages: [LanguageCode],
        bookDescription: String? = nil,
        coverImageName: String,
        bookCode: String,
        subBooks: [SubBook]
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.languages = languages
        self.bookDescription = bookDescription
        self.coverImageName = coverImageName
        self.bookCode = bookCode
        self.subBooks = subBooks
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Validatable
    
    func validate(with languages: [LanguageCode] = []) throws {
        let validationLanguages = languages.isEmpty ? self.languages : languages
        
        // Ensure that there is at least one subBook.
        if subBooks.isEmpty {
            throw ValidationError.missingSubBooks
        }
        for subBook in subBooks {
            try subBook.validate(with: validationLanguages)
        }
    }
}
