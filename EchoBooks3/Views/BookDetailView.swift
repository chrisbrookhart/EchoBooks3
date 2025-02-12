import SwiftUI
import SwiftData

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

    // New state for auto-advancement:
    @State private var currentSentenceIndex: Int = 0
    @State private var advancementTimer: Timer? = nil

    // New state to track manual slider interaction.
    @State private var isUserEditingSlider: Bool = false

    // MARK: - Playback Options State
    @State private var selectedLanguage1: String = "English"
    @State private var selectedLanguage2: String = "None"
    @State private var selectedLanguage3: String = "None"

    @State private var selectedSpeed1: Double = 1.0
    @State private var selectedSpeed2: Double = 1.0
    @State private var selectedSpeed3: Double = 1.0

    // MARK: - Audio Playback Manager Integration
    @StateObject private var audioManager = AudioPlaybackManager()
    
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
    
    // Computed Boolean for end-of-book status.
    private var isAtEnd: Bool {
        guard let content = chapterContent else { return true }
        let totalSentencesInChapter = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let atEndOfChapter = currentSentenceIndex >= totalSentencesInChapter - 1
        let isLastChapter = selectedChapterIndex == (selectedSubBook.chapters.count - 1)
        let isLastSubBook = selectedSubBookIndex == (book.subBooks.count - 1)
        return atEndOfChapter && isLastChapter && isLastSubBook
    }
    
    // MARK: - Initial Restoration Flag
    @State private var hasRestoredState: Bool = false
    
    // For a slider that directly represents sentence indices:
    var maxSliderValue: Double {
        totalSentences > 0 ? Double(totalSentences - 1) : 0.0
    }
    
    var body: some View {
        GeometryReader { geo in
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
                    
                    // --- Sentence Display ---
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
                        .disabled(currentSentenceIndex == 0)
                        .foregroundColor(currentSentenceIndex == 0 ? .gray : .primary)
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
                            Image(systemName: isAtEnd || !isPlaying ? "play.circle.fill" : "pause.circle.fill")
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
                    Slider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                sliderValue = newValue
                                let targetIndex = Int(round(newValue))
                                currentSentenceIndex = targetIndex
                                if let sentence = chapterContent.flatMap({ getCurrentSentence(from: $0, at: targetIndex) }) {
                                    currentSentence = sentence.text
                                    // When a new sentence is loaded, load its audio and auto-play.
                                    audioManager.loadAudio(for: sentence)
                                    audioManager.play()
                                }
                                saveBookState()
                                updateGlobalAppStateForBookDetail()
                            }
                        ),
                        in: 0...maxSliderValue,
                        onEditingChanged: { _ in
                            saveBookState()
                            updateGlobalAppStateForBookDetail()
                        }
                    )
                    .padding(.horizontal)
                    
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
                currentSentenceIndex = bookState?.lastGlobalSentenceIndex ?? 0
                sliderValue = 0.0
                if let content = chapterContent,
                   let sentence = getCurrentSentence(from: content, at: currentSentenceIndex) {
                    currentSentence = sentence.text
                    let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
                    sliderValue = total > 1 ? Double(currentSentenceIndex) / Double(total - 1) * maxSliderValue : 0.0
                    // When restoring the sentence, load its audio and auto-play.
                    audioManager.loadAudio(for: sentence)
                    audioManager.play()
                }
                DispatchQueue.main.async {
                    hasRestoredState = true
                }
            }
            .onDisappear {
                saveBookState()
                updateGlobalAppStateForBookDetail()
                stopAdvancementTimer()
                audioManager.pause()
            }
        }
        .navigationTitle(book.bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedSubBookIndex) { _, _ in
            if hasRestoredState {
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
                if let sentence = currentSentenceContent() {
                    audioManager.loadAudio(for: sentence)
                    audioManager.play()
                }
            }
        }
        .onChange(of: selectedChapterIndex) { _, _ in
            if hasRestoredState {
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
                if let sentence = currentSentenceContent() {
                    audioManager.loadAudio(for: sentence)
                    audioManager.play()
                }
            }
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
            audioManager.setRate(Float($0))
        }
        .onChange(of: selectedSpeed2) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            audioManager.setRate(Float($0))
        }
        .onChange(of: selectedSpeed3) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            audioManager.setRate(Float($0))
        }
    }
    
    // MARK: - Helper: Get Current SentenceContent
    private func currentSentenceContent() -> SentenceContent? {
        if let content = chapterContent {
            return getCurrentSentence(from: content, at: currentSentenceIndex)
        }
        return nil
    }
    
    // MARK: - Skip Button Actions
    private func skipBackwardAction() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = max(currentSentenceIndex - 5, 0)
        currentSentenceIndex = newIndex
        sliderValue = total > 1 ? Double(newIndex) / Double(total - 1) * maxSliderValue : 0.0
        if let sentence = getCurrentSentence(from: content, at: newIndex) {
            currentSentence = sentence.text
            audioManager.loadAudio(for: sentence)
            audioManager.play()
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    private func skipForwardAction() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = min(currentSentenceIndex + 5, total - 1)
        currentSentenceIndex = newIndex
        sliderValue = total > 1 ? Double(newIndex) / Double(total - 1) * maxSliderValue : 0.0
        if let sentence = getCurrentSentence(from: content, at: newIndex) {
            currentSentence = sentence.text
            audioManager.loadAudio(for: sentence)
            audioManager.play()
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    // MARK: - Auto-Advancement Functions
    private func startAdvancementTimer() {
        stopAdvancementTimer()
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
            currentSentenceIndex += 1
            sliderValue = Double(currentSentenceIndex) / Double(total - 1) * maxSliderValue
            if let sentence = getCurrentSentence(from: content, at: currentSentenceIndex) {
                currentSentence = sentence.text
                audioManager.loadAudio(for: sentence)
                if isPlaying {
                    audioManager.play()
                }
            }
            saveBookState()
            updateGlobalAppStateForBookDetail()
        } else {
            if selectedChapterIndex < selectedSubBook.chapters.count - 1 {
                selectedChapterIndex += 1
                currentSentenceIndex = 0
                sliderValue = 0.0
                chapterContent = loadChapterContent()
                if let content = chapterContent,
                   let firstSentence = getCurrentSentence(from: content, at: 0) {
                    currentSentence = firstSentence.text
                    audioManager.loadAudio(for: firstSentence)
                    if isPlaying {
                        audioManager.play()
                    }
                }
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else if selectedSubBookIndex < book.subBooks.count - 1 {
                selectedSubBookIndex += 1
                selectedChapterIndex = 0
                currentSentenceIndex = 0
                sliderValue = 0.0
                chapterContent = loadChapterContent()
                if let content = chapterContent,
                   let firstSentence = getCurrentSentence(from: content, at: 0) {
                    currentSentence = firstSentence.text
                    audioManager.loadAudio(for: firstSentence)
                    if isPlaying {
                        audioManager.play()
                    }
                }
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else {
                stopAdvancementTimer()
                isPlaying = false
            }
        }
    }
    
    // MARK: - Update Current Sentence on Selection Change
    private func updateCurrentSentenceForSelection() {
        chapterContent = loadChapterContent()
        currentSentenceIndex = 0
        sliderValue = 0.0
        if let content = chapterContent,
           let firstSentence = getCurrentSentence(from: content, at: 0) {
            currentSentence = firstSentence.text
            audioManager.loadAudio(for: firstSentence)
            audioManager.play()
        } else {
            currentSentence = "No sentence available."
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
                return nil
            }
        } else {
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
            currentSentenceIndex = state.lastGlobalSentenceIndex
            selectedLanguage1 = state.selectedLanguage1
            selectedLanguage2 = state.selectedLanguage2
            selectedLanguage3 = state.selectedLanguage3
            selectedSpeed1 = state.selectedSpeed1
            selectedSpeed2 = state.selectedSpeed2
            selectedSpeed3 = state.selectedSpeed3
        } else {
            let newState = BookState(bookID: targetBookID)
            newState.lastGlobalSentenceIndex = 0
            modelContext.insert(newState)
            bookState = newState
        }
    }
    
    private func saveBookState() {
        guard let state = bookState else { return }
        state.lastSubBookIndex = selectedSubBookIndex
        state.lastChapterIndex = selectedChapterIndex
        state.lastSliderValue = sliderValue
        state.lastGlobalSentenceIndex = currentSentenceIndex
        state.selectedLanguage1 = selectedLanguage1
        state.selectedLanguage2 = selectedLanguage2
        state.selectedLanguage3 = selectedLanguage3
        state.selectedSpeed1 = selectedSpeed1
        state.selectedSpeed2 = selectedSpeed2
        state.selectedSpeed3 = selectedSpeed3
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
        } else {
            let newAppState = AppState(lastOpenedView: .bookDetail, lastOpenedBookID: book.id)
            newAppState.id = globalStateID
            modelContext.insert(newAppState)
            try? modelContext.save()
        }
    }
}
