import SwiftUI
import SwiftData

//// MARK: - Chapter JSON Models
//
//struct ChapterContent: Decodable {
//    let chapterID: String
//    let language: String
//    let chapterNumber: Int
//    let chapterTitle: String
//    let paragraphs: [ParagraphContent]
//}
//
//struct ParagraphContent: Decodable {
//    let paragraphID: String
//    let paragraphIndex: Int
//    let sentences: [SentenceContent]
//}
//
//struct SentenceContent: Decodable {
//    let sentenceID: String
//    let sentenceIndex: Int
//    let globalSentenceIndex: Int
//    let reference: String?
//    let text: String
//    let audioFile: String
//}

// MARK: - BookDetailView

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext

    // MARK: - Navigation & Content State
    @State private var selectedSubBookIndex: Int = 0
    @State private var selectedChapterIndex: Int = 0

    // MARK: - Content Display & Playback State
    @State private var currentSentence: String = "Loading sentence..."
    @State private var sliderValue: Double = 0.0
    @State private var isPlaying: Bool = false

    // New state for auto-advancement (used elsewhere)
    @State private var currentSentenceIndex: Int = 0
    @State private var advancementTimer: Timer? = nil

    // MARK: - Playback Options State
    @State private var selectedLanguage1: String = "English"
    @State private var selectedLanguage2: String = "None"
    @State private var selectedLanguage3: String = "None"
    
    @State private var selectedSpeed1: Double = 1.0
    @State private var selectedSpeed2: Double = 1.0
    @State private var selectedSpeed3: Double = 1.0

    // Speed options for playback.
    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    // Available language names from the book's languages.
    var availableLanguageNames: [String] {
        book.languages.map { $0.name }
    }
    var availableLanguagesWithNone: [String] {
        ["None"] + availableLanguageNames
    }

    // Convenience computed properties.
    var selectedSubBook: SubBook {
        book.subBooks[selectedSubBookIndex]
    }
    var selectedChapter: Chapter {
        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
            return selectedSubBook.chapters.first!
        }
        return selectedSubBook.chapters[selectedChapterIndex]
    }
    
    // MARK: - Persistence State
    @State private var bookState: BookState?

    // MARK: - Chapter Content State
    @State private var chapterContent: ChapterContent?
    
    // Total number of sentences in the current chapter.
    var totalSentences: Int {
        chapterContent?.paragraphs.reduce(0) { $0 + $1.sentences.count } ?? 0
    }
    
    // Computed booleans for button states.
    var isAtBeginning: Bool {
        currentSentenceIndex == 0
    }
    var isAtEnd: Bool {
        if totalSentences > 0 {
            return currentSentenceIndex == (totalSentences - 1)
        }
        return false
    }
    
    var body: some View {
        GeometryReader { geo in
            // Compute total sentences (if available) for button state.
            let _ = totalSentences  // This forces evaluation of totalSentences.
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- Subbook Picker ---
                    if book.subBooks.count > 1 {
                        HStack {
                            Spacer()
                            Picker("Subbook", selection: $selectedSubBookIndex) {
                                ForEach(0..<book.subBooks.count, id: \.self) { index in
                                    Text(book.subBooks[index].subBookTitle).tag(index)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // --- Chapter Picker ---
                    if selectedSubBook.chapters.count > 1 {
                        HStack {
                            Spacer()
                            Picker("Chapter", selection: $selectedChapterIndex) {
                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // --- Content Display: Sentence Text Box ---
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                        Text(currentSentence)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: geo.size.height * 0.4)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // --- Playback Controls ---
                    HStack {
                        Spacer()
                        Button(action: {
                            skipBackwardAction()
                        }) {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .font(.title)
                        }
                        .disabled(isAtBeginning)
                        .foregroundColor(isAtBeginning ? .gray : .primary)
                        
                        Spacer()
                        Button(action: {
                            if isPlaying {
                                isPlaying = false
                                stopAdvancementTimer()
                            } else if !isAtEnd {
                                isPlaying = true
                                startAdvancementTimer()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                        }
                        .foregroundColor(isAtEnd ? .gray : .primary)
                        .disabled(isAtEnd)
                        
                        Spacer()
                        Button(action: {
                            skipForwardAction()
                        }) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .font(.title)
                        }
                        .disabled(isAtEnd)
                        .foregroundColor(isAtEnd ? .gray : .primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // --- Slider for Chapter Navigation ---
                    Slider(value: $sliderValue, in: 0...100)
                        .padding(.horizontal)
                        .onChange(of: sliderValue) { newValue in
                            guard totalSentences > 0 else { return }
                            let fraction = newValue / 100.0
                            let targetIndex = Int(Double(totalSentences - 1) * fraction)
                            currentSentenceIndex = targetIndex
                            if let sentence = chapterContent.flatMap({ getCurrentSentence(from: $0, at: targetIndex) }) {
                                currentSentence = sentence.text
                            }
                            saveBookState()
                            updateGlobalAppStateForBookDetail()
                        }
                    
                    // --- Playback Options: Language and Speed Pickers ---
                    VStack(alignment: .leading, spacing: 16) {
                        PlaybackOptionRowView(
                            selectedLanguage: $selectedLanguage1,
                            selectedSpeed: $selectedSpeed1,
                            availableLanguages: availableLanguageNames,
                            speedOptions: speedOptions
                        )
                        PlaybackOptionRowView(
                            selectedLanguage: $selectedLanguage2,
                            selectedSpeed: $selectedSpeed2,
                            availableLanguages: availableLanguagesWithNone,
                            speedOptions: speedOptions
                        )
                        PlaybackOptionRowView(
                            selectedLanguage: $selectedLanguage3,
                            selectedSpeed: $selectedSpeed3,
                            availableLanguages: availableLanguagesWithNone,
                            speedOptions: speedOptions
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .onAppear {
                loadBookState()
                updateGlobalAppStateForBookDetail()
                chapterContent = loadChapterContent()
                currentSentenceIndex = 0
                sliderValue = 0.0
                if let content = chapterContent,
                   let firstSentence = getCurrentSentence(from: content, at: 0) {
                    currentSentence = firstSentence.text
                    print("Loaded first sentence: \(firstSentence.text)")
                }
            }
            .onDisappear {
                saveBookState()
                updateGlobalAppStateForBookDetail()
                stopAdvancementTimer()
            }
        }
        .navigationTitle(book.bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        // onChange handlers for other state variables.
        .onChange(of: selectedSubBookIndex) {
            updateCurrentSentenceForSelection()
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedChapterIndex) {
            updateCurrentSentenceForSelection()
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedLanguage1) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedLanguage2) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedLanguage3) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedSpeed1) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedSpeed2) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedSpeed3) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
    }
    
    // MARK: - Skip Button Actions
    
    private func skipBackwardAction() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = max(currentSentenceIndex - 5, 0)
        currentSentenceIndex = newIndex
        sliderValue = (total > 1 ? Double(newIndex) / Double(total - 1) * 100.0 : 0.0)
        if let sentence = getCurrentSentence(from: content, at: newIndex) {
            currentSentence = sentence.text
            print("Skipped backward to sentence: \(sentence.text)")
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    private func skipForwardAction() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = min(currentSentenceIndex + 5, total - 1)
        currentSentenceIndex = newIndex
        sliderValue = (total > 1 ? Double(newIndex) / Double(total - 1) * 100.0 : 0.0)
        if let sentence = getCurrentSentence(from: content, at: newIndex) {
            currentSentence = sentence.text
            print("Skipped forward to sentence: \(sentence.text)")
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    // MARK: - Auto-Advancement Functions
    
    private func startAdvancementTimer() {
        stopAdvancementTimer() // Cancel any existing timer.
        advancementTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            advanceSentence()
        }
    }
    
    private func stopAdvancementTimer() {
        advancementTimer?.invalidate()
        advancementTimer = nil
    }
    
    private func advanceSentence() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        
        if currentSentenceIndex < total - 1 {
            // Advance within the current chapter.
            currentSentenceIndex += 1
            sliderValue = Double(currentSentenceIndex) / Double(total - 1) * 100.0
            if let sentence = getCurrentSentence(from: content, at: currentSentenceIndex) {
                currentSentence = sentence.text
                print("Advanced to sentence: \(sentence.text)")
            }
            saveBookState()
            updateGlobalAppStateForBookDetail()
        } else {
            // End of current chapter reached.
            if selectedChapterIndex < selectedSubBook.chapters.count - 1 {
                // Move to next chapter in the current subbook.
                selectedChapterIndex += 1
                currentSentenceIndex = 0
                sliderValue = 0.0
                chapterContent = loadChapterContent()
                if let content = chapterContent,
                   let firstSentence = getCurrentSentence(from: content, at: 0) {
                    currentSentence = firstSentence.text
                    print("Advanced to next chapter, first sentence: \(firstSentence.text)")
                }
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else if selectedSubBookIndex < book.subBooks.count - 1 {
                // Move to next subbook.
                selectedSubBookIndex += 1
                selectedChapterIndex = 0
                currentSentenceIndex = 0
                sliderValue = 0.0
                chapterContent = loadChapterContent()
                if let content = chapterContent,
                   let firstSentence = getCurrentSentence(from: content, at: 0) {
                    currentSentence = firstSentence.text
                    print("Advanced to next subbook, first chapter, first sentence: \(firstSentence.text)")
                }
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else {
                // End of the entire book reached.
                print("Reached the end of the book. Auto-advancement stopped.")
                stopAdvancementTimer()
                isPlaying = false
            }
        }
    }
    
    private func updateCurrentSentenceForSelection() {
        chapterContent = loadChapterContent()
        currentSentenceIndex = 0
        sliderValue = 0.0
        if let content = chapterContent,
           let firstSentence = getCurrentSentence(from: content, at: 0) {
            currentSentence = firstSentence.text
            print("Updated current sentence for new selection: \(firstSentence.text)")
        } else {
            currentSentence = "No sentence available."
            print("Unable to update current sentence for the current selection.")
        }
    }
    
    // MARK: - JSON Parsing Helpers
    
    private func chapterJSONFileName(language: String = "en-US") -> String {
        let bookCode = book.bookCode
        let subNumber = selectedSubBook.subBookNumber
        let chapterNum = selectedChapter.chapterNumber
        return "\(bookCode)_S\(subNumber)_C\(chapterNum)_\(language).json"
    }
    
    private func loadChapterContent() -> ChapterContent? {
        let fileName = chapterJSONFileName()
        let resource = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        if let url = Bundle.main.url(forResource: resource, withExtension: ext) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let content = try decoder.decode(ChapterContent.self, from: data)
                return content
            } catch {
                print("Error decoding chapter JSON: \(error)")
                return nil
            }
        } else {
            print("Unable to find chapter JSON file: \(fileName)")
            return nil
        }
    }
    
    private func getCurrentSentence(from chapter: ChapterContent, at targetIndex: Int) -> SentenceContent? {
        let total = chapter.paragraphs.reduce(0) { $0 + $1.sentences.count }
        guard total > 0 else { return nil }
        var runningIndex = 0
        for paragraph in chapter.paragraphs {
            if runningIndex + paragraph.sentences.count > targetIndex {
                let indexInParagraph = targetIndex - runningIndex
                return paragraph.sentences[indexInParagraph]
            }
            runningIndex += paragraph.sentences.count
        }
        return nil
    }
    
    // MARK: - Persistence Helper Functions
    
    private func loadBookState() {
        let targetBookID = book.id
        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
            return state.bookID == targetBookID
        })
        if let state = try? modelContext.fetch(fetchRequest).first {
            bookState = state
            selectedSubBookIndex = state.lastSubBookIndex
            selectedChapterIndex = state.lastChapterIndex
            sliderValue = state.lastSliderValue
            selectedLanguage1 = state.selectedLanguage1
            selectedLanguage2 = state.selectedLanguage2
            selectedLanguage3 = state.selectedLanguage3
            selectedSpeed1 = state.selectedSpeed1
            selectedSpeed2 = state.selectedSpeed2
            selectedSpeed3 = state.selectedSpeed3
            print("Loaded persisted state for book: \(book.bookTitle)")
        } else {
            let newState = BookState(bookID: targetBookID)
            modelContext.insert(newState)
            bookState = newState
            print("No persisted state found; created new state for book: \(book.bookTitle)")
        }
    }
    
    private func saveBookState() {
        guard let state = bookState else { return }
        state.lastSubBookIndex = selectedSubBookIndex
        state.lastChapterIndex = selectedChapterIndex
        state.lastSliderValue = sliderValue
        state.selectedLanguage1 = selectedLanguage1
        state.selectedLanguage2 = selectedLanguage2
        state.selectedLanguage3 = selectedLanguage3
        state.selectedSpeed1 = selectedSpeed1
        state.selectedSpeed2 = selectedSpeed2
        state.selectedSpeed3 = selectedSpeed3
        print("Saving state for book: \(book.bookTitle)")
        try? modelContext.save()
    }
    
    private func updateGlobalAppStateForBookDetail() {
        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
            return state.id == globalStateID
        })
        if let appState = try? modelContext.fetch(fetchRequest).first {
            appState.lastOpenedView = .bookDetail
            appState.lastOpenedBookID = book.id
            try? modelContext.save()
            print("Updated global AppState for book: \(book.bookTitle)")
        } else {
            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
            newAppState.id = globalStateID
            modelContext.insert(newAppState)
            try? modelContext.save()
            print("Created global AppState for book: \(book.bookTitle)")
        }
    }
}

struct PlaybackOptionRowView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedSpeed: Double
    let availableLanguages: [String]
    let speedOptions: [Double]
    
    var body: some View {
        HStack {
            Picker("", selection: $selectedLanguage) {
                ForEach(availableLanguages, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Picker("", selection: $selectedSpeed) {
                ForEach(speedOptions, id: \.self) { speed in
                    Text(String(format: "%.2f", speed)).tag(speed)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}



//// displays first sentence in chapter based on user selection
//
//import SwiftUI
//import SwiftData
//
////// MARK: - Chapter JSON Models
////
////struct ChapterContent: Decodable {
////    let chapterID: String
////    let language: String
////    let chapterNumber: Int
////    let chapterTitle: String
////    let paragraphs: [ParagraphContent]
////}
////
////struct ParagraphContent: Decodable {
////    let paragraphID: String
////    let paragraphIndex: Int
////    let sentences: [SentenceContent]
////}
////
////struct SentenceContent: Decodable {
////    let sentenceID: String
////    let sentenceIndex: Int
////    let globalSentenceIndex: Int
////    let reference: String?
////    let text: String
////    let audioFile: String
////}
//
//// MARK: - BookDetailView
//
//struct BookDetailView: View {
//    let book: Book
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - Navigation & Content State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//    
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name }
//    }
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//
//    // MARK: - Persistence State
//    @State private var bookState: BookState?
//
//    // MARK: - Chapter Content State
//    @State private var chapterContent: ChapterContent?
//    
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    
//                    // --- Subbook Picker ---
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Chapter Picker ---
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Content Display: Sentence Text Box ---
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // --- Playback Controls (Placeholders) ---
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Placeholder for skip backward.
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Placeholder for skip forward.
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // --- Slider for Chapter Navigation ---
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // --- Playback Options: Language and Speed Pickers ---
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .onAppear {
//                loadBookState()
//                updateGlobalAppStateForBookDetail()
//                // Load chapter content and update current sentence.
//                chapterContent = loadChapterContent()
//                updateCurrentSentenceForSelection()
//            }
//            .onDisappear {
//                saveBookState()
//                updateGlobalAppStateForBookDetail()
//            }
//        }
//        .navigationTitle(book.bookTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        // onChange handlers for immediate persistence and dynamic sentence update.
//        .onChange(of: selectedSubBookIndex) {
//            updateCurrentSentenceForSelection()
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedChapterIndex) {
//            updateCurrentSentenceForSelection()
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: sliderValue) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage1) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage2) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage3) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed1) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed2) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed3) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//    }
//    
//    // MARK: - Dynamic Sentence Loading Helper
//    
//    /// Updates the current sentence based on the current subbook and chapter selection.
//    /// This function loads the chapter content from the appropriate JSON file and sets the
//    /// current sentence to the first sentence (index 0) of that chapter.
//    private func updateCurrentSentenceForSelection() {
//        // Reload chapter content for the current chapter.
//        chapterContent = loadChapterContent()
//        if let content = chapterContent, let firstSentence = getCurrentSentence(from: content, at: 0) {
//            currentSentence = firstSentence.text
//            sliderValue = 0.0  // Reset slider to the start.
//            print("Updated current sentence for new selection: \(firstSentence.text)")
//        } else {
//            currentSentence = "No sentence available."
//            print("Unable to update current sentence for the current selection.")
//        }
//    }
//    
//    // MARK: - JSON Parsing Helpers
//    
//    /// Computes the chapter JSON file name based on the naming convention:
//    /// "{bookCode}_S{subBookNumber}_C{chapterNumber}_en-US.json"
//    private func chapterJSONFileName(language: String = "en-US") -> String {
//        let bookCode = book.bookCode
//        let subNumber = selectedSubBook.subBookNumber
//        let chapterNum = selectedChapter.chapterNumber
//        return "\(bookCode)_S\(subNumber)_C\(chapterNum)_\(language).json"
//    }
//    
//    /// Loads and decodes the chapter content from the JSON file in the main bundle.
//    private func loadChapterContent() -> ChapterContent? {
//        let fileName = chapterJSONFileName()
//        let resource = (fileName as NSString).deletingPathExtension
//        let ext = (fileName as NSString).pathExtension
//        if let url = Bundle.main.url(forResource: resource, withExtension: ext) {
//            do {
//                let data = try Data(contentsOf: url)
//                let decoder = JSONDecoder()
//                let content = try decoder.decode(ChapterContent.self, from: data)
//                return content
//            } catch {
//                print("Error decoding chapter JSON: \(error)")
//                return nil
//            }
//        } else {
//            print("Unable to find chapter JSON file: \(fileName)")
//            return nil
//        }
//    }
//    
//    /// Given a ChapterContent and a target sentence index, returns the corresponding SentenceContent.
//    private func getCurrentSentence(from chapter: ChapterContent, at targetIndex: Int) -> SentenceContent? {
//        let total = chapter.paragraphs.reduce(0) { $0 + $1.sentences.count }
//        guard total > 0 else { return nil }
//        var runningIndex = 0
//        for paragraph in chapter.paragraphs {
//            if runningIndex + paragraph.sentences.count > targetIndex {
//                let indexInParagraph = targetIndex - runningIndex
//                return paragraph.sentences[indexInParagraph]
//            }
//            runningIndex += paragraph.sentences.count
//        }
//        return nil
//    }
//    
//    // MARK: - Persistence Helper Functions
//    
//    private func loadBookState() {
//        let targetBookID = book.id
//        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
//            return state.bookID == targetBookID
//        })
//        if let state = try? modelContext.fetch(fetchRequest).first {
//            bookState = state
//            selectedSubBookIndex = state.lastSubBookIndex
//            selectedChapterIndex = state.lastChapterIndex
//            sliderValue = state.lastSliderValue
//            selectedLanguage1 = state.selectedLanguage1
//            selectedLanguage2 = state.selectedLanguage2
//            selectedLanguage3 = state.selectedLanguage3
//            selectedSpeed1 = state.selectedSpeed1
//            selectedSpeed2 = state.selectedSpeed2
//            selectedSpeed3 = state.selectedSpeed3
//            print("Loaded persisted state for book: \(book.bookTitle)")
//        } else {
//            let newState = BookState(bookID: targetBookID)
//            modelContext.insert(newState)
//            bookState = newState
//            print("No persisted state found; created new state for book: \(book.bookTitle)")
//        }
//    }
//    
//    private func saveBookState() {
//        guard let state = bookState else { return }
//        state.lastSubBookIndex = selectedSubBookIndex
//        state.lastChapterIndex = selectedChapterIndex
//        state.lastSliderValue = sliderValue
//        state.selectedLanguage1 = selectedLanguage1
//        state.selectedLanguage2 = selectedLanguage2
//        state.selectedLanguage3 = selectedLanguage3
//        state.selectedSpeed1 = selectedSpeed1
//        state.selectedSpeed2 = selectedSpeed2
//        state.selectedSpeed3 = selectedSpeed3
//        print("Saving state for book: \(book.bookTitle)")
//        try? modelContext.save()
//    }
//    
//    private func updateGlobalAppStateForBookDetail() {
//        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
//        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
//            return state.id == globalStateID
//        })
//        if let appState = try? modelContext.fetch(fetchRequest).first {
//            appState.lastOpenedView = .bookDetail
//            appState.lastOpenedBookID = book.id
//            try? modelContext.save()
//            print("Updated global AppState for book: \(book.bookTitle)")
//        } else {
//            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
//            newAppState.id = globalStateID
//            modelContext.insert(newAppState)
//            try? modelContext.save()
//            print("Created global AppState for book: \(book.bookTitle)")
//        }
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}



//// BookDetailView.swift - works, before AudioManager integration
//
//import SwiftUI
//import SwiftData
//
//struct BookDetailView: View {
//    let book: Book
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - Navigation & Content State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name }
//    }
//    // For rows 2 and 3, include "None" as an option.
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//
//    // MARK: - Persistence State
//    @State private var bookState: BookState?
//
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    
//                    // --- Subbook Picker (menu style, centered) ---
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Chapter Picker (centered using chapterTitle) ---
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Content Display: Sentence Text Box ---
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // --- Playback Controls ---
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Skip backward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Skip forward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // --- Slider for Chapter Navigation ---
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // --- Playback Options: Language and Speed Pickers ---
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .onAppear {
//                loadBookState()
//                updateGlobalAppStateForBookDetail()
//            }
//            .onDisappear {
//                saveBookState()
//                updateGlobalAppStateForBookDetail()
//            }
//        }
//        .navigationTitle(book.bookTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        // Attach onChange handlers for immediate persistence.
//        // Note that fixing deprecation warning merely requires deleting " _ in" (to make it a zero parameter function)
//        .onChange(of: selectedSubBookIndex) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedChapterIndex) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: sliderValue) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage1) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage2) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedLanguage3) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed1) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed2) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//        .onChange(of: selectedSpeed3) {
//            saveBookState()
//            updateGlobalAppStateForBookDetail()
//        }
//    }
//    
//    // MARK: - Persistence Helper Functions
//    private func loadBookState() {
//        let targetBookID = book.id
//        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
//            return state.bookID == targetBookID
//        })
//        if let state = try? modelContext.fetch(fetchRequest).first {
//            bookState = state
//            selectedSubBookIndex = state.lastSubBookIndex
//            selectedChapterIndex = state.lastChapterIndex
//            sliderValue = state.lastSliderValue
//            selectedLanguage1 = state.selectedLanguage1
//            selectedLanguage2 = state.selectedLanguage2
//            selectedLanguage3 = state.selectedLanguage3
//            selectedSpeed1 = state.selectedSpeed1
//            selectedSpeed2 = state.selectedSpeed2
//            selectedSpeed3 = state.selectedSpeed3
//            print("Loaded persisted state for book: \(book.bookTitle)")
//        } else {
//            let newState = BookState(bookID: targetBookID)
//            modelContext.insert(newState)
//            bookState = newState
//            print("No persisted state found; created new state for book: \(book.bookTitle)")
//        }
//    }
//    
//    private func saveBookState() {
//        guard let state = bookState else { return }
//        state.lastSubBookIndex = selectedSubBookIndex
//        state.lastChapterIndex = selectedChapterIndex
//        state.lastSliderValue = sliderValue
//        state.selectedLanguage1 = selectedLanguage1
//        state.selectedLanguage2 = selectedLanguage2
//        state.selectedLanguage3 = selectedLanguage3
//        state.selectedSpeed1 = selectedSpeed1
//        state.selectedSpeed2 = selectedSpeed2
//        state.selectedSpeed3 = selectedSpeed3
//        print("Saving state for book: \(book.bookTitle)")
//        try? modelContext.save()
//    }
//    
//    private func updateGlobalAppStateForBookDetail() {
//        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
//        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
//            return state.id == globalStateID
//        })
//        if let appState = try? modelContext.fetch(fetchRequest).first {
//            appState.lastOpenedView = .bookDetail
//            appState.lastOpenedBookID = book.id
//            try? modelContext.save()
//            print("Updated global AppState for book: \(book.bookTitle)")
//        } else {
//            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
//            newAppState.id = globalStateID
//            modelContext.insert(newAppState)
//            try? modelContext.save()
//            print("Created global AppState for book: \(book.bookTitle)")
//        }
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}




////works but not for force quit (this is before adding the onChange handlers)
//import SwiftUI
//import SwiftData
//
//struct BookDetailView: View {
//    let book: Book
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - Navigation & Content State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name }
//    }
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//
//    // Persistence state for this book.
//    @State private var bookState: BookState?
//
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Subbook Picker
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // Chapter Picker using chapterTitle
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // Content Display: Sentence Text Box
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // Playback Controls
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Skip backward (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Skip forward (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // Slider for Chapter Navigation
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // Playback Options: Language and Speed Pickers
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .onAppear {
//                loadBookState()         // Load per-book state.
//                updateGlobalAppStateForBookDetail() // Update global AppState.
//            }
//            .onDisappear {
//                saveBookState()         // Save per-book state.
//                updateGlobalAppStateForBookDetail() // Update global AppState again.
//            }
//        }
//        .navigationTitle(book.bookTitle)
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // MARK: - Persistence Helper Functions
//    private func loadBookState() {
//        let targetBookID = book.id
//        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
//            return state.bookID == targetBookID
//        })
//        if let state = try? modelContext.fetch(fetchRequest).first {
//            bookState = state
//            selectedSubBookIndex = state.lastSubBookIndex
//            selectedChapterIndex = state.lastChapterIndex
//            sliderValue = state.lastSliderValue
//            selectedLanguage1 = state.selectedLanguage1
//            selectedLanguage2 = state.selectedLanguage2
//            selectedLanguage3 = state.selectedLanguage3
//            selectedSpeed1 = state.selectedSpeed1
//            selectedSpeed2 = state.selectedSpeed2
//            selectedSpeed3 = state.selectedSpeed3
//            print("Loaded persisted state for book: \(book.bookTitle)")
//        } else {
//            let newState = BookState(bookID: targetBookID)
//            modelContext.insert(newState)
//            bookState = newState
//            print("No persisted state found; created new state for book: \(book.bookTitle)")
//        }
//    }
//    
//    private func saveBookState() {
//        guard let state = bookState else { return }
//        state.lastSubBookIndex = selectedSubBookIndex
//        state.lastChapterIndex = selectedChapterIndex
//        state.lastSliderValue = sliderValue
//        state.selectedLanguage1 = selectedLanguage1
//        state.selectedLanguage2 = selectedLanguage2
//        state.selectedLanguage3 = selectedLanguage3
//        state.selectedSpeed1 = selectedSpeed1
//        state.selectedSpeed2 = selectedSpeed2
//        state.selectedSpeed3 = selectedSpeed3
//        print("Saving state for book: \(book.bookTitle)")
//        try? modelContext.save()
//    }
//    
//    private func updateGlobalAppStateForBookDetail() {
//        // Use a fixed global state identifier.
//        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
//        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
//            return state.id == globalStateID
//        })
//        if let appState = try? modelContext.fetch(fetchRequest).first {
//            appState.lastOpenedView = .bookDetail
//            appState.lastOpenedBookID = book.id
//            try? modelContext.save()
//            print("Updated global AppState for book: \(book.bookTitle)")
//        } else {
//            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
//            newAppState.id = globalStateID
//            modelContext.insert(newAppState)
//            try? modelContext.save()
//            print("Created global AppState for book: \(book.bookTitle)")
//        }
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}


// working except for returning to open book after closing the app
//import SwiftUI
//import SwiftData
//
//struct BookDetailView: View {
//    let book: Book
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - Navigation & Content State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name }
//    }
//    // For rows 2 and 3, include "None" as an option.
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//
//    // MARK: - Persistence State
//    @State private var bookState: BookState?
//
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // --- Subbook Picker (menu style, centered) ---
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Chapter Picker (centered using chapterTitle) ---
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Content Display: Sentence Text Box ---
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // --- Playback Controls ---
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Skip backward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Skip forward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // --- Slider for Chapter Navigation ---
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // --- Playback Options: Language and Speed Pickers ---
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .onAppear {
//                loadBookState()        // Step 2: Load persisted BookState.
//                updateGlobalAppStateForBookDetail()  // Step 4: Update global AppState.
//            }
//            .onDisappear {
//                saveBookState()        // Save persisted state on view disappearance.
//            }
//        }
//        .navigationTitle(book.bookTitle)
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // MARK: - Persistence Helper Functions
//    private func loadBookState() {
//        let targetBookID = book.id
//        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
//            return state.bookID == targetBookID
//        })
//        if let state = try? modelContext.fetch(fetchRequest).first {
//            bookState = state
//            selectedSubBookIndex = state.lastSubBookIndex
//            selectedChapterIndex = state.lastChapterIndex
//            sliderValue = state.lastSliderValue
//            selectedLanguage1 = state.selectedLanguage1
//            selectedLanguage2 = state.selectedLanguage2
//            selectedLanguage3 = state.selectedLanguage3
//            selectedSpeed1 = state.selectedSpeed1
//            selectedSpeed2 = state.selectedSpeed2
//            selectedSpeed3 = state.selectedSpeed3
//            print("Loaded persisted state for book: \(book.bookTitle)")
//        } else {
//            let newState = BookState(bookID: targetBookID)
//            modelContext.insert(newState)
//            bookState = newState
//            print("No persisted state found; created new state for book: \(book.bookTitle)")
//        }
//    }
//    
//    private func saveBookState() {
//        guard let state = bookState else { return }
//        state.lastSubBookIndex = selectedSubBookIndex
//        state.lastChapterIndex = selectedChapterIndex
//        state.lastSliderValue = sliderValue
//        state.selectedLanguage1 = selectedLanguage1
//        state.selectedLanguage2 = selectedLanguage2
//        state.selectedLanguage3 = selectedLanguage3
//        state.selectedSpeed1 = selectedSpeed1
//        state.selectedSpeed2 = selectedSpeed2
//        state.selectedSpeed3 = selectedSpeed3
//        print("Saving state for book: \(book.bookTitle)")
//        try? modelContext.save()
//    }
//    
//    private func updateGlobalAppStateForBookDetail() {
//        // Define a fixed global state identifier.
//        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
//        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
//            return state.id == globalStateID
//        })
//        if let appState = try? modelContext.fetch(fetchRequest).first {
//            appState.lastOpenedView = .bookDetail
//            appState.lastOpenedBookID = book.id
//            try? modelContext.save()
//            print("Updated global AppState for book: \(book.bookTitle)")
//        } else {
//            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
//            newAppState.id = globalStateID
//            modelContext.insert(newAppState)
//            try? modelContext.save()
//            print("Created global AppState for book: \(book.bookTitle)")
//        }
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}



//Persistent states working for book
//import SwiftUI
//import SwiftData
//
//struct BookDetailView: View {
//    let book: Book
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - Navigation & Content State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name }
//    }
//    // For rows 2 and 3, include "None" as an option.
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//
//    // MARK: - Persistence State
//    @State private var bookState: BookState?
//
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // --- Subbook Picker (menu style, centered) ---
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Chapter Picker (centered using chapterTitle) ---
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Content Display: Sentence Text Box ---
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3)
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // --- Playback Controls ---
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Skip backward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Skip forward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // --- Slider for Chapter Navigation ---
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // --- Playback Options: Language and Speed Pickers ---
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .onAppear {
//                loadBookState()  // Step 2: Load persisted state and update UI state variables.
//            }
//            .onDisappear {
//                saveBookState()  // Save the state when the view disappears.
//            }
//        }
//        .navigationTitle(book.bookTitle)
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // MARK: - Persistence Helper Functions (Step 2)
//    private func loadBookState() {
//        // Capture the book's ID in a local constant to avoid scoping issues.
//        let targetBookID = book.id
//        // Build a predicate using the generic form of the #Predicate macro.
//        let fetchRequest = FetchDescriptor<BookState>(predicate: #Predicate<BookState> { state in
//            return state.bookID == targetBookID
//        })
//        if let state = try? modelContext.fetch(fetchRequest).first {
//            bookState = state
//            selectedSubBookIndex = state.lastSubBookIndex
//            selectedChapterIndex = state.lastChapterIndex
//            sliderValue = state.lastSliderValue
//            selectedLanguage1 = state.selectedLanguage1
//            selectedLanguage2 = state.selectedLanguage2
//            selectedLanguage3 = state.selectedLanguage3
//            selectedSpeed1 = state.selectedSpeed1
//            selectedSpeed2 = state.selectedSpeed2
//            selectedSpeed3 = state.selectedSpeed3
//            print("Loaded persisted state for book: \(book.bookTitle)")
//        } else {
//            let newState = BookState(bookID: targetBookID)
//            modelContext.insert(newState)
//            bookState = newState
//            print("No persisted state found; created new state for book: \(book.bookTitle)")
//        }
//    }
//    
//    private func saveBookState() {
//        guard let state = bookState else { return }
//        state.lastSubBookIndex = selectedSubBookIndex
//        state.lastChapterIndex = selectedChapterIndex
//        state.lastSliderValue = sliderValue
//        state.selectedLanguage1 = selectedLanguage1
//        state.selectedLanguage2 = selectedLanguage2
//        state.selectedLanguage3 = selectedLanguage3
//        state.selectedSpeed1 = selectedSpeed1
//        state.selectedSpeed2 = selectedSpeed2
//        state.selectedSpeed3 = selectedSpeed3
//        print("Saving state for book: \(book.bookTitle)")
//        try? modelContext.save()
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}







//import SwiftUI
//
//struct BookDetailView: View {
//    let book: Book
//    
//    // MARK: - Navigation & Persistence State
//    @State private var selectedSubBookIndex: Int = 0
//    @State private var selectedChapterIndex: Int = 0
//    
//    // MARK: - Content Display & Playback State
//    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
//    @State private var sliderValue: Double = 0.0
//    @State private var isPlaying: Bool = false
//    
//    // MARK: - Playback Options State
//    @State private var selectedLanguage1: String = "English"
//    @State private var selectedLanguage2: String = "None"
//    @State private var selectedLanguage3: String = "None"
//    
//    @State private var selectedSpeed1: Double = 1.0
//    @State private var selectedSpeed2: Double = 1.0
//    @State private var selectedSpeed3: Double = 1.0
//    
//    // Speed options for playback.
//    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
//    
//    // Available language names from the book's languages.
//    var availableLanguageNames: [String] {
//        book.languages.map { $0.name } // Assumes LanguageCode.name now returns, e.g., "English"
//    }
//    var availableLanguagesWithNone: [String] {
//        ["None"] + availableLanguageNames
//    }
//    
//    // Convenience computed properties.
//    var selectedSubBook: SubBook {
//        book.subBooks[selectedSubBookIndex]
//    }
//    var selectedChapter: Chapter {
//        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
//            return selectedSubBook.chapters.first!
//        }
//        return selectedSubBook.chapters[selectedChapterIndex]
//    }
//    
//    var body: some View {
//        GeometryReader { geo in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // --- Subbook Picker (menu-style, centered) ---
//                    if book.subBooks.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Subbook", selection: $selectedSubBookIndex) {
//                                ForEach(0..<book.subBooks.count, id: \.self) { index in
//                                    Text(book.subBooks[index].subBookTitle).tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Chapter Picker (centered) ---
//                    if selectedSubBook.chapters.count > 1 {
//                        HStack {
//                            Spacer()
//                            Picker("Chapter", selection: $selectedChapterIndex) {
//                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
//                                    Text("Chapter \(selectedSubBook.chapters[index].chapterNumber)").tag(index)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // --- Content Display: Sentence Text Box ---
//                    ZStack {
//                        Color(UIColor.secondarySystemBackground)
//                        Text(currentSentence)
//                            .font(.title3) // Larger font that respects system settings
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                    .frame(height: geo.size.height * 0.4)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                    
//                    // --- Playback Controls ---
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Skip backward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.counterclockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                        Button(action: {
//                            isPlaying.toggle()
//                        }) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 50))
//                        }
//                        Spacer()
//                        Button(action: {
//                            // Skip forward action (placeholder)
//                        }) {
//                            Image(systemName: "arrow.trianglehead.clockwise")
//                                .font(.title)
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    
//                    // --- Slider for Chapter Navigation ---
//                    Slider(value: $sliderValue, in: 0...100)
//                        .padding(.horizontal)
//                    
//                    // --- Playback Options: Language and Speed Pickers ---
//                    VStack(alignment: .leading, spacing: 16) {
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage1,
//                            selectedSpeed: $selectedSpeed1,
//                            availableLanguages: availableLanguageNames,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage2,
//                            selectedSpeed: $selectedSpeed2,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                        PlaybackOptionRowView(
//                            selectedLanguage: $selectedLanguage3,
//                            selectedSpeed: $selectedSpeed3,
//                            availableLanguages: availableLanguagesWithNone,
//                            speedOptions: speedOptions
//                        )
//                    }
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                }
//                .padding(.vertical)
//            }
//            .navigationTitle(book.bookTitle)
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}
//
//struct PlaybackOptionRowView: View {
//    @Binding var selectedLanguage: String
//    @Binding var selectedSpeed: Double
//    let availableLanguages: [String]
//    let speedOptions: [Double]
//    
//    var body: some View {
//        HStack {
//            // Language picker on the left.
//            Picker("", selection: $selectedLanguage) {
//                ForEach(availableLanguages, id: \.self) { lang in
//                    Text(lang).tag(lang)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//            
//            // Speed picker on the right.
//            Picker("", selection: $selectedSpeed) {
//                ForEach(speedOptions, id: \.self) { speed in
//                    Text(String(format: "%.2f", speed)).tag(speed)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}
//
//
