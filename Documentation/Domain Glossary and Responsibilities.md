# EchoBooks Domain Glossary and Responsibilities

## 1. Key Domain Entities

- **Book**  
  *Definition:* A container for a single audiobook that includes metadata (title, author, description, cover image, etc.) and a hierarchical structure of content.  
  *Responsibilities:*  
  - Represent the overall book information.
  - Organize content into subbooks and chapters.
  - Provide language availability data for playback.

- **SubBook**  
  *Definition:* A logical grouping within a Book. For flat books, a “default” subbook is used; for books with natural divisions, each subbook might represent a section (e.g., "Introduction", "Chapters 1-3", etc.).  
  *Responsibilities:*  
  - Organize chapters.
  - Maintain a subbook title and order within the book.

- **Chapter**  
  *Definition:* A subdivision of a Book (or SubBook) representing a segment of content (e.g., a chapter in an audiobook).  
  *Responsibilities:*  
  - Contain content divided into Paragraphs.
  - Provide chapter-level metadata (e.g., chapter title, chapter number).

- **Paragraph**  
  *Definition:* A block of text in a chapter. In the domain, a paragraph is a collection of sentences.  
  *Responsibilities:*  
  - Group related sentences together.
  - Serve as a unit for certain playback modes (e.g., Paragraph mode plays all sentences in a paragraph before switching languages).

- **Sentence**  
  *Definition:* The smallest unit of text content, stored along with its audio file reference and global index.  
  *Responsibilities:*  
  - Provide the text and associated audio file for playback.
  - Maintain a global sentence index that is continuous throughout the book.

- **LanguageCode**  
  *Definition:* An enumeration representing the supported language codes (e.g., "en-US", "es-ES").  
  *Responsibilities:*  
  - Define the available languages.
  - Provide both raw code values (for file naming and internal logic) and display names (for UI).

- **PlaybackMode**  
  *Definition:* An enumeration that indicates the mode of playback. The two primary modes are:  
  - **Sentence mode:** Plays one sentence at a time per language.  
  - **Paragraph mode:** Plays all sentences in a paragraph in one language before repeating the same paragraph in another language.  
  *Responsibilities:*  
  - Control the flow of playback.
  - Influence how the playback use case transitions between sentences, paragraphs, and chapters.

## 2. Domain Processes and Use Cases

### A. **Playback Domain**

- **Responsibilities:**  
  - Manage starting, pausing, resuming, and stopping audio playback.
  - Advance playback according to the selected mode:
    - *Sentence Mode:* Cycle through one sentence at a time in each selected language.
    - *Paragraph Mode:* Play all sentences in the current paragraph in the primary language, then replay the entire paragraph in the secondary (and tertiary) language(s) if available, before advancing to the next paragraph or chapter.
  - Switch languages based on user settings and current playback stage.
  - Set playback speeds per language.

- **Key Domain Interfaces:**  
  - `PlaybackUseCase` with methods like `play()`, `pause()`, `skipForward()`, `skipBackward()`, and `audioDidFinishPlaying()`.
  - Concrete implementations (e.g., `PlaybackInteractor`) that encapsulate the detailed business logic for transitioning between sentences, paragraphs, chapters, and subbooks.

### B. **Navigation Domain**

- **Responsibilities:**  
  - Map a “global sentence index” (a cumulative index across the chapter) to the specific paragraph and sentence.
  - Calculate progress within a chapter (or paragraph) to drive UI elements like sliders.
  - Manage transitions when reaching the end of a paragraph, chapter, or subbook.
  - Provide helper methods (e.g., to compute the start of the next paragraph or the first sentence of the current paragraph).

- **Key Domain Interfaces:**  
  - `NavigationUseCase` with methods like `advanceSentence()`, `resetToFirstSentence()`, `nextParagraphStartIndex()`, and helper methods for computing paragraph boundaries.

### C. **Content Loading Domain**

- **Responsibilities:**  
  - Load and parse chapter JSON files into structured domain objects (Paragraphs, Sentences).
  - Isolate file system access and parsing logic from business logic.
  - Provide a unified interface for loading chapter content for a given language.

- **Key Domain Interfaces:**  
  - `ContentLoader` with a method like `loadChapterContent(language: String, for chapter: Chapter) -> ChapterContent?`.

### D. **Persistence Domain (State Management)**

- **Responsibilities:**  
  - Save and load the user’s reading state (such as the last opened view, current chapter, global sentence index, etc.).
  - Provide mechanisms for persisting app-level and book-specific state, using frameworks like SwiftData or AppStorage.
  - Expose interfaces that allow the business logic (e.g., PlaybackInteractor or NavigationInteractor) to store and retrieve state.

- **Key Domain Interfaces:**  
  - `StateRepository` with methods such as `loadBookState(bookID: UUID) -> BookState?` and `saveBookState(state: BookState)`.

## 3. How They Work Together

- The **PlaybackInteractor** (domain) uses the **ContentLoader** to get chapter content, the **NavigationUseCase** to determine which sentence or paragraph to play next, and the **StateRepository** to persist the current reading state.  
- The **BookDetailViewModel** (presentation layer) invokes methods on the **PlaybackUseCase** to perform actions like play, pause, or skip, and it exposes current state (like the current sentence text and progress) to the UI.  
- The **BookDetailView** (UI layer) observes the view model’s published properties and binds UI controls (such as the slider, play/pause button, and chapter selection) to these properties and actions.  
- **Persistence** (handled by the StateRepository and AppState models) is updated when significant transitions occur (e.g., advancing a sentence, changing chapters), ensuring that the last opened view or chapter is restored when the app reopens.

## 4. Coordination and Communication

- **Ubiquitous Language:** All team members use terms like “global sentence index,” “playback mode,” “paragraph mode,” etc., consistently across documentation, code comments, and discussions.  
- **Diagrams:** Use simple UML-like block diagrams to show how the domain protocols (PlaybackUseCase, NavigationUseCase, ContentLoader, StateRepository) interact with concrete implementations and the view model.  
- **Documentation:** Maintain a living document (or wiki) that details each domain’s responsibilities, use case methods, and expected behavior in edge cases (like transitioning between chapters).


