

---

## Book Model Documentation

### Overview
The **Book** model represents a single book within the EchoBooks application. It captures the essential metadata (such as title, author, and cover image) as well as the hierarchical structure of the book through its subBooks relationship. Every book must have at least one subBook. For flat books without natural sub-divisions, a default subBook is used.

### Purpose and Responsibilities
- **Representing Book Metadata:**  
  Store basic information about the book, such as its title, author, description, and cover image.
  
- **Defining Language Availability:**  
  Maintain an array of `LanguageCode` values representing the languages in which the book is available.
  
- **Modeling Book Structure:**  
  Hold a collection of subBook objects (each representing a section of the book), where each subBook contains chapters.
  
- **Validation:**  
  Ensure that the book is properly structured (e.g., it must contain at least one subBook) by conforming to the `Validatable` protocol.

### Properties and Mapping
- **id (UUID):**  
  Unique identifier for the book. Mapped from the JSON field `"bookID"`.
  
- **bookTitle (String):**  
  The title of the book. Corresponds directly to the JSON key `"bookTitle"`.
  
- **author (String):**  
  The author or translator of the book. Maps from the JSON key `"author"`.
  
- **languages ([LanguageCode]):**  
  An array of language codes (using the `LanguageCode` enum) that indicates in which languages the book is available. This comes from the JSON key `"languages"`.
  
- **bookDescription (String?):**  
  An optional description of the book, from the JSON key `"bookDescription"`.
  
- **coverImageName (String):**  
  The filename of the book’s cover image, mapped from `"coverImageName"`.
  
- **bookCode (String):**  
  A short code used to uniquely identify the book in file naming (e.g., `"BOOKM"`). This comes from the JSON key `"bookCode"`.
  
- **subBooks ([SubBook]):**  
  An array of subBook objects that define the hierarchical sections of the book. Each subBook further contains its own chapters. This property maps from the JSON key `"subBooks"`.

### Initialization and Decoding
- **Decodable:**  
  The model conforms to the `Decodable` protocol so that it can be constructed directly from the book structure JSON (e.g., `BOOKM_structure.json`). The coding keys match the JSON keys exactly.
  
- **Initializers:**  
  There is a required initializer (used for decoding) and a designated initializer for programmatic creation of Book objects.

### Validation
- The model implements the `Validatable` protocol to ensure that:
  - The `subBooks` array is not empty.
  - Each subBook is validated against the provided language settings.
  
This validation is important to guarantee that the book’s structure adheres to the expected format before further processing.

### Example Diagram (Textual Representation)
```
Book
 ├── id: UUID                  // Maps from JSON "bookID"
 ├── bookTitle: String         // JSON "bookTitle"
 ├── author: String            // JSON "author"
 ├── languages: [LanguageCode] // JSON "languages"
 ├── bookDescription: String?  // JSON "bookDescription"
 ├── coverImageName: String    // JSON "coverImageName"
 ├── bookCode: String          // JSON "bookCode"
 └── subBooks: [SubBook]       // JSON "subBooks" (each SubBook contains its own chapters)
```

### How to Use This Documentation
- **For Developers:**  
  When reading or modifying the code, refer to this document to understand which JSON fields map to which properties. It also clarifies how the model ensures data integrity via validation.
  
- **For an LLM or Future Code Review:**  
  This documentation provides a clear, structured explanation of the Book model’s role in the app and how it interacts with other parts of the system (like the subBooks and chapter models). It aligns with the overall content and file structure documentation, ensuring consistency across the project.

---

---
UML Class Diagram

+--------------------------------------------------+
|                     Book                         |
+--------------------------------------------------+
| - id: UUID                                       |
| - bookTitle: String                              |
| - author: String                                 |
| - languages: [LanguageCode]                      |
| - bookDescription: String?                       |
| - coverImageName: String                         |
| - bookCode: String                               |
| - subBooks: [SubBook]                            |
+--------------------------------------------------+
| + init(id: UUID,                                |
|        bookTitle: String,                        |
|        author: String,                           |
|        languages: [LanguageCode],                |
|        bookDescription: String?,                 |
|        coverImageName: String,                   |
|        bookCode: String,                         |
|        subBooks: [SubBook])                       |
| + validate(with: [LanguageCode]) throws          |
| + ==(lhs: Book, rhs: Book) : Bool                 |
| + hash(into: inout Hasher)                       |
+--------------------------------------------------+
---