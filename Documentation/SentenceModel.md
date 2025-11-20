Below is a complete documentation for the **Sentence** model, including a description of its purpose, properties, responsibilities, and behavior during decoding and validation. A UML class diagram is provided at the end.

---

## Sentence Model Documentation

### Overview
The **Sentence** model represents an individual sentence within a paragraph of a book. It is a core element of the hierarchical structure where a Paragraph contains multiple Sentence objects. In addition to storing the sentence’s text and its position (both within its paragraph and globally across the book), the model also maintains a mapping from each available language to both the text and the associated audio filename. This enables the app to support multilingual playback. The model conforms to protocols for identification, decoding, validation, and hashing.

### Purpose and Responsibilities
- **Sentence Identification & Ordering:**  
  Each Sentence has a unique identifier and stores two indexes:
  - **sentenceIndex:** Its local position within a paragraph.
  - **globalSentenceIndex:** A continuous index used for navigation across the entire book.
  
- **Language-Specific Content:**  
  The model uses dictionaries keyed by `LanguageCode` to store:
  - **Text:** The sentence’s content in various languages.
  - **Audio Files:** The corresponding audio file names for each language (if available).
  
- **Reference Information:**  
  The model includes a `reference` property to store additional information (e.g., scripture references) that might be associated with the sentence.
  
- **Decoding:**  
  When decoding from a language-specific JSON file, it assumes the JSON contains data for one language. It extracts the text and optionally the audio filename, then initializes its dictionaries with a single key–value pair. The language is determined from the decoder’s `userInfo` under the key `.languageCodeKey`, defaulting to `"en-US"` if not provided.
  
- **Validation:**  
  The model implements the `Validatable` protocol to ensure that for each requested language there is corresponding text (and audio, if applicable) and that the sentence is associated with a parent paragraph.

### Properties and JSON Mapping
- **id (UUID):**  
  Unique identifier for the sentence. Mapped from the JSON key `"sentenceID"`.

- **sentenceIndex (Int):**  
  The sentence’s sequential index within its parent paragraph.

- **globalSentenceIndex (Int):**  
  A continuous index across the entire book used for navigation.

- **reference (String):**  
  An optional reference string (e.g., a scripture reference) that applies to the sentence.

- **text ([LanguageCode: String]):**  
  A dictionary mapping each language (as a `LanguageCode`) to the sentence text. In the decoding process, only one language’s text is read, and the dictionary is initialized with that value.

- **audioFiles ([LanguageCode: String]?):**  
  An optional dictionary mapping each language to the corresponding audio filename. Like the text, it is initialized from the JSON if the value exists.

- **paragraph (Paragraph?):**  
  An optional reference to the parent Paragraph. This relationship may be set later by SwiftData.

### Decoding & Initialization
- **Decodable Conformance:**  
  The model defines a private `CodingKeys` enum to map JSON keys to properties. The custom `init(from:)`:
  - Decodes basic properties (id, sentenceIndex, globalSentenceIndex, and reference).
  - Decodes the text for one language from the JSON. It reads the language code from the decoder’s `userInfo` (using a key like `.languageCodeKey`) and defaults to `"en-US"` if absent.
  - Optionally decodes the audio file value and initializes the `audioFiles` dictionary if available.
  
- **Designated Initializer:**  
  There is also an initializer that allows for programmatic creation of a Sentence, accepting values for all properties including the text and audio files dictionaries.

### Validation
- **Validatable Protocol:**  
  The `validate(with:)` method ensures:
  - For every requested language in a given array, the `text` dictionary must contain a value.
  - If the `audioFiles` dictionary is present, it must contain an entry for every requested language.
  - The sentence must be associated with a parent paragraph (throwing an error if not).

### UML Class Diagram

```plaintext
+--------------------------------------------------------------+
|                          Sentence                            |
+--------------------------------------------------------------+
| - id: UUID                                                   |
| - sentenceIndex: Int                                           |
| - globalSentenceIndex: Int                                     |
| - reference: String                                            |
| - text: [LanguageCode: String]                                 |
| - audioFiles: [LanguageCode: String]?                          |
| - paragraph: Paragraph?                                        |
+--------------------------------------------------------------+
| + init(id: UUID, sentenceIndex: Int,                           |
|        globalSentenceIndex: Int, reference: String,            |
|        text: [LanguageCode: String],                           |
|        audioFiles: [LanguageCode: String]? = nil,               |
|        paragraph: Paragraph? = nil)                             |
| + init(from decoder: Decoder) throws                           |
| + validate(with languages: [LanguageCode]) throws              |
| + ==(lhs: Sentence, rhs: Sentence) -> Bool                     |
| + hash(into: inout Hasher)                                     |
+--------------------------------------------------------------+
```

*Note: The `CodingKeys` enum is an internal detail for decoding and is not shown in the diagram.*

### Usage Guidelines
- **For Developers:**  
  Use the Sentence model to decode and represent individual sentences. When merging content from multiple languages, you may need to update the dictionaries accordingly. Always perform validation using the `validate(with:)` method after decoding to ensure that the sentence contains all required language data.
  
- **For Future LLMs and Code Reviews:**  
  This documentation, along with the UML diagram, offers a clear description of the Sentence model's structure and behavior. It outlines the mapping from the JSON structure to the model's properties and describes how language-specific data is managed. This should help ensure consistency and clarity when maintaining or extending the codebase.

---

