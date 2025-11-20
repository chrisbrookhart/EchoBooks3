Below is a complete documentation that describes the book structure JSON (using an example book) along with an explanation of the file hierarchy and naming conventions. 

---

# EchoBooks Content & File Structure Documentation

This document explains how the book content and audio files are organized in the EchoBooks app. It details the folder hierarchy, naming conventions, and the contents of the book structure JSON file. Use this as a reference when developing, debugging, or extending the app.

---

## 1. Overall Directory Structure

Each book is stored in its own top-level folder. Within that folder, the following items are found:

- **Book Structure JSON:**  
  A file that contains the overall metadata and content organization for the book. Its name follows the format:  
  **`{bookCode}_structure.json`**

- **Language Folders:**  
  Each language in which the book is available has its own folder (named with the language code, e.g., `en-US`, `es-ES`, `fr-FR`). Within each language folder, there are two subfolders:
  - **Content:** Contains the chapter JSON files (organized by subbook and chapter).
  - **Audio:** Contains the audio files corresponding to the text content.

### Example Hierarchy

```
The_Book_of_Mormon/
├── BOOKM_structure.json              // Book-level JSON file with metadata and content organization.
├── en-US/                           // English language folder.
│   ├── Content/                     // Contains chapter JSON files.
│   │   └── [Subbook Folder]         // E.g., "1-Default" or "1-Introduction and Witnesses".
│   │       └── ChapterX/           // Each chapter is stored in its own folder.
│   │           └── BOOKM_S1_CX_en-US.json  // Chapter JSON file.
│   └── Audio/                       // Contains audio files for English.
│       └── [Subbook Folder]         // Mirroring the content folder structure.
│           └── ChapterX/
│               └── 0000001_BOOKM_S1_CX_PY_S1_en-US.aac  // Audio file.
├── es-ES/                           // Spanish language folder (same structure as en-US).
└── fr-FR/                           // French language folder (same structure as en-US).
```

---

## 2. File Naming Conventions

### A. Book Structure JSON

- **File Name Format:**  
  `{bookCode}_structure.json`

- **Example:**  
  `BOOKM_structure.json`

- **Contents Overview:**  
  This JSON file contains both metadata and the hierarchical structure of the book. It includes:
  
  - **bookID:** A unique identifier (UUID) for the book.
  - **bookTitle:** The title of the book.
  - **author:** The author (or translator) of the book.
  - **languages:** An array of language codes available for the book (e.g., `["en-US", "es-ES", "fr-FR"]`).
  - **bookDescription:** A brief description of the book.
  - **coverImageName:** The filename for the cover image.
  - **bookCode:** A short code used in naming other files.
  - **defaultPlaybackOrder:** An array that defines the default order in which languages are played.
  - **subBooks:** An array of subBook objects. Each subBook represents a logical section of the book (for example, if the book has natural divisions like “Introduction and Witnesses”, “1 Nephi”, and “Moroni”). For flat books, a default subBook (e.g., titled "Default") is used.

#### A.1 subBook Object (Nested within Book Structure JSON)

Each subBook in the `subBooks` array includes:

- **subBookID:** A unique identifier (UUID) for the subBook.
- **subBookNumber:** A numeric order for the subBook.
- **subBookTitle:** The title of the subBook (e.g., "Introduction and Witnesses", "1 Nephi", "Moroni").
- **chapters:** An array of chapter objects within that subBook.

##### A.1.1 Chapter Object (Nested within subBook Object)

Each chapter object includes:

- **chapterID:** A unique identifier (UUID) for the chapter.
- **chapterNumber:** The chapter’s sequential number.
- **chapterTitle:** The title of the chapter.
- **totalParagraphs:** The number of paragraphs in the chapter.
- **totalSentences:** The total number of sentences in the chapter.
- **contentReferences:** A dictionary that maps language codes to the corresponding chapter JSON filename.
  
  **Example of a chapter object:**
  
  ```json
  {
      "chapterID": "dbfd8a0a-d7b4-435e-aeb7-cf50b3956f1c",
      "chapterNumber": 1,
      "chapterTitle": "Title Page Of The Book Of Mormon",
      "totalParagraphs": 2,
      "totalSentences": 2,
      "contentReferences": {
          "en-US": "BOOKM_S1_C1_en-US.json",
          "es-ES": "BOOKM_S1_C1_es-ES.json",
          "fr-FR": "BOOKM_S1_C1_fr-FR.json"
      }
  }
  ```

### B. Chapter JSON Files

- **File Name Format:**  
  `{bookCode}_S{subbook_number}_C{chapter_number}_{language}.json`

- **Example:**  
  `BOOKM_S1_C3_en-US.json`

- **Contents:**  
  Each chapter JSON file contains:
  - **chapterID, chapterNumber, chapterTitle** (repeating what’s in the structure JSON).
  - **paragraphs:** An array where each element represents a paragraph.
    - Each paragraph object has:
      - **paragraphID:** A unique identifier.
      - **paragraphIndex:** The paragraph’s position within the chapter.
      - **sentences:** An array of sentence objects.
        - Each sentence object includes:
          - **sentenceID:** A unique identifier.
          - **sentenceIndex:** The sentence’s sequential number within the paragraph.
          - **globalSentenceIndex:** A continuous counter for the sentence within the entire book.
          - **text:** The sentence text.
          - **audioFile:** The filename for the corresponding audio file.

### C. Audio Files

- **File Name Format:**  
  `{global_sentence_index padded to 7 digits}_{bookCode}_S{subbook_number}_C{chapter_number}_P{paragraph_number}_S{sentence_number}_{language}.aac`

- **Example:**  
  `0000001_BOOKM_S1_C3_P1_S2_en-US.aac`

- **Purpose:**  
  Each audio file is the spoken version of a sentence. The file’s name includes:
  - A zero-padded global sentence index.
  - The book code.
  - The subBook number.
  - The chapter number.
  - The paragraph number.
  - The sentence number.
  - The language code.

---

## 3. Relationships and Mapping

- **Mapping Content to Audio:**  
  The chapter JSON files (stored under the Content folder of each language) include a `globalSentenceIndex` for each sentence. This index is used to locate the corresponding audio file in the Audio folder. For instance, a sentence with `globalSentenceIndex` 1 in the `en-US` version should have a matching audio file named like `0000001_BOOKM_S1_C3_P1_S2_en-US.aac`.

- **Global Sentence Index:**  
  This index is continuous across the entire book (it does not reset with each chapter) and is crucial for synchronizing text with its corresponding audio file.

---

## 4. Content Pipeline

### Step-by-Step Process

1. **Parsing:**  
   - A raw text file for a book is processed (using tools such as a sentence parser) to divide the text into chapters, paragraphs, and sentences.
   
2. **JSON Generation:**  
   - The parsed content is used to generate the book structure JSON (`{bookCode}_structure.json`), which contains metadata and an array of subBooks.  
   - Each subBook includes its chapters, and each chapter JSON file (named according to the convention) is generated for each language.
   
3. **Audio Generation:**  
   - For each sentence (or paragraph, depending on the playback mode), an audio file is generated using a text-to-speech or audio synthesis API.  
   - These files are saved in the corresponding Audio folder using the naming convention.
   
4. **Verification:**  
   - The app verifies that each chapter JSON and its corresponding audio files exist and adhere to the expected schema.  
   - This verification helps ensure that the content and audio remain synchronized.

---

## 5. Maintenance and Extension Guidelines

- **Consistency:**  
  Any modifications to the naming conventions or directory structure must be reflected in the content loading logic within the app. Changes should be coordinated among the text parser, JSON generator, and audio generation pipelines.
  
- **Documentation Updates:**  
  Keep this document (or a section in your project’s README) up to date with any changes in the file structure or naming conventions.
  
- **Diagrams:**  
  Although not as formal as UML, simple block diagrams can be useful. For example, you might diagram the folder hierarchy as a tree and include annotations for how files are named and mapped. A sample diagram could be:

  ```
  [The_Book_of_Mormon]
      │
      ├── BOOKM_structure.json
      │
      ├── [en-US]
      │    ├── Content
      │    │    └── [Subbook Folder]
      │    │         └── ChapterX
      │    │              └── BOOKM_S1_CX_en-US.json
      │    └── Audio
      │         └── [Subbook Folder]
      │              └── ChapterX
      │                   └── 0000001_BOOKM_S1_CX_PY_S1_en-US.aac
      │
      ├── [es-ES]  (similar structure)
      │
      └── [fr-FR]  (similar structure)
  ```

- **Collaboration:**  
  Use this document as the basis for discussions with your team or with an LLM. When new features or changes are proposed, refer back to these conventions and the pipeline overview to ensure that all aspects of the app remain in sync.

---

