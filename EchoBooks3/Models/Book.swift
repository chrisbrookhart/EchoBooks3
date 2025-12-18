//
//  Book.swift

//
//  This model represents a book. SubBooks are optional - for new format books,
//  a default subbook is created automatically. For old format books, subBooks
//  are provided in the JSON structure.
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
    
    /// The level of the book (optional).
    var bookLevel: Int?
    
    /// The learning theme of the book (optional).
    var learningTheme: String?
    
    /// What the user will practice with this book (optional).
    var whatYouWillPractice: [String]?
    
    /// Estimated length of the book (optional).
    var estimatedLength: String?
    
    /// Whether the book is free (true) or requires a subscription (false).
    var isFree: Bool
    
    /// StoreKit product identifier for this book (optional, only for downloadable books).
    var productIdentifier: String?
    
    // MARK: - Relationships
    
    /// The subbooks in this book. Optional - for new format books, a default subbook is created.
    /// For old format books, this array contains the subbooks from the JSON structure.
    @Relationship var subBooks: [SubBook]?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id = "bookID"
        case bookTitle
        case author
        case languages
        case bookDescription
        case coverImageName
        case bookCode
        case bookLevel
        case learningTheme
        case whatYouWillPractice
        case estimatedLength
        case isFree
        case productIdentifier
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
        self.bookLevel = try container.decodeIfPresent(Int.self, forKey: .bookLevel)
        self.learningTheme = try container.decodeIfPresent(String.self, forKey: .learningTheme)
        self.whatYouWillPractice = try container.decodeIfPresent([String].self, forKey: .whatYouWillPractice)
        self.estimatedLength = try container.decodeIfPresent(String.self, forKey: .estimatedLength)
        self.isFree = try container.decodeIfPresent(Bool.self, forKey: .isFree) ?? false // Default to false if not present
        self.productIdentifier = try container.decodeIfPresent(String.self, forKey: .productIdentifier)
        // subBooks is optional - decode if present, otherwise nil
        self.subBooks = try container.decodeIfPresent([SubBook].self, forKey: .subBooks)
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
        bookLevel: Int? = nil,
        learningTheme: String? = nil,
        whatYouWillPractice: [String]? = nil,
        estimatedLength: String? = nil,
        isFree: Bool = false,
        productIdentifier: String? = nil,
        subBooks: [SubBook]? = nil
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.languages = languages
        self.bookDescription = bookDescription
        self.coverImageName = coverImageName
        self.bookCode = bookCode
        self.bookLevel = bookLevel
        self.learningTheme = learningTheme
        self.whatYouWillPractice = whatYouWillPractice
        self.estimatedLength = estimatedLength
        self.isFree = isFree
        self.productIdentifier = productIdentifier
        self.subBooks = subBooks
    }
    
    // MARK: - Computed Properties
    
    /// Returns the subBooks array, or an empty array if nil.
    /// This provides safe access for code that expects a non-optional array.
    var effectiveSubBooks: [SubBook] {
        return subBooks ?? []
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
        
        // If subBooks is nil or empty, that's acceptable for new format books
        // (they will have a default subbook created during import)
        guard let subBooks = subBooks, !subBooks.isEmpty else {
            // For new format books, validation passes even without subBooks
            // The BookImporter ensures a default subbook is created
            return
        }
        
        // Validate each subBook if they exist
        for subBook in subBooks {
            try subBook.validate(with: validationLanguages)
        }
    }
}
