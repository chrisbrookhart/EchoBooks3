Below is a complete documentation of the Chapter model. It explains its purpose, structure, responsibilities, and usage for both future developers and LLMs. A UML class diagram is provided at the end.

---

## Chapter Model Documentation

### Overview
The **Chapter** model represents a chapter within a book. It is part of a hierarchical data model where a Book contains one or more subBooks, and each subBook contains an array of Chapter objects. The Chapter model holds chapter-level metadata and an array of Paragraph objects (which in turn contain Sentence objects). This model is designed to work with a unified structure JSON file, where extra keys such as `"totalParagraphs"`, `"totalSentences"`, and `"contentReferences"` are ignored during decoding.

### Purpose and Responsibilities
- **Chapter Metadata:**  
  Store essential details of a chapter including its unique identifier, chapter number, title, and the language in which the chapter is written.
  
- **Hierarchical Content:**  
  Maintain an array of `Paragraph` objects that represent the segmented text within the chapter.
  
- **Language Defaulting:**  
  If the `"language"` key is missing during decoding, the model defaults the chapter language to `.enUS`. This ensures that the chapter always has a valid language code.
  
- **Validation:**  
  Implements the `Validatable` protocol to allow for checking the integrity of its content. In this case, if no paragraphs exist, it assumes the chapter is a structure-level chapter and does not throw an error.

### Properties and Mapping
- **id (UUID):**  
  Unique identifier for the chapter. It maps from the JSON key `"chapterID"`.

- **language (LanguageCode):**  
  Represents the language of the chapter. If missing in the JSON, it defaults to `.enUS`.

- **chapterNumber (Int):**  
  A sequential number representing the chapter’s order in the book. Maps from the JSON key `"chapterNumber"`.

- **chapterTitle (String):**  
  The title of the chapter, typically extracted from the first line of the chapter text. Maps from the JSON key `"chapterTitle"`.

- **paragraphs ([Paragraph]):**  
  An array of Paragraph objects containing the chapter’s text. Maps from the JSON key `"paragraphs"`. If this key is missing, it defaults to an empty array.

### Decoding & Validation
- **Decodable Conformance:**  
  The model conforms to `Decodable` and uses an internal `CodingKeys` enum to map JSON keys to its properties. If the `"language"` key is absent, it automatically defaults to `.enUS`.

- **Validation:**  
  The `validate(with:)` method checks that the chapter’s paragraphs are valid. If no paragraphs are present, it simply returns without error, assuming that the chapter might be a structural placeholder.

### UML Class Diagram

```plaintext
+-----------------------------------------------------+
|                      Chapter                        |
+-----------------------------------------------------+
| - id: UUID                                          |
| - language: LanguageCode                            |
| - chapterNumber: Int                                |
| - chapterTitle: String                              |
| - paragraphs: [Paragraph]                           |
+-----------------------------------------------------+
| + init(id: UUID,                                   |
|        chapterTitle: String,                        |
|        chapterNumber: Int,                          |
|        language: LanguageCode,                      |
|        paragraphs: [Paragraph])                    |
| + init(from decoder: Decoder) throws               |
| + validate(with languages: [LanguageCode]) throws    |
| + ==(lhs: Chapter, rhs: Chapter) -> Bool            |
| + hash(into: inout Hasher)                          |
+-----------------------------------------------------+
```

*Note: The `CodingKeys` enum and any internal helper methods are considered implementation details and are not shown in the UML diagram.*

### Usage Guidelines
- **For Developers:**  
  Use this model to decode chapter JSON files that follow the unified structure. Ensure that when creating a new Chapter instance, an array of Paragraph objects is provided—even if empty—to maintain consistency. Always call `validate(with:)` after decoding to check the chapter’s content.
  
- **For LLMs/Future Code Reviews:**  
  This documentation provides a clear mapping between the JSON structure and the model properties. The UML diagram visually summarizes the key properties and public methods, helping to understand the relationships and responsibilities within the app’s data model.

---

