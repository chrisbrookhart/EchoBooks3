//
//  BookDetailView.swift
//  EchoBooks3
//
//  Revised to support multi-language playback and per-language speed selection.
//  When the user pauses and then resumes, playback continues from the same position.
//  The play/pause action now reattaches the onPlaybackFinished callback on resume so that the
//  chain of language playback (advancing from language 1 to language 2, etc.) occurs correctly.
//

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
    @State private var isPlaying: Bool = false {
        didSet { print("[DEBUG] isPlaying changed to \(isPlaying)") }
    }
    @State private var currentSentenceIndex: Int = 0

    /// Playback stage:
    /// 1 = primary language (selectedLanguage1),
    /// 2 = secondary (selectedLanguage2),
    /// 3 = tertiary (selectedLanguage3).
    @State private var currentPlaybackStage: Int = 1

    /// Flag to indicate if chapter/subbook change is internal.
    @State private var internalNavigation: Bool = false

    /// Flag to track if playback was paused (to enable resuming from same location).
    @State private var didPause: Bool = false

    // MARK: - Playback Options State
    @State private var selectedLanguage1: String = "English"
    @State private var selectedLanguage2: String = "None"
    @State private var selectedLanguage3: String = "None"

    @State private var selectedSpeed1: Double = 1.0
    @State private var selectedSpeed2: Double = 1.0
    @State private var selectedSpeed3: Double = 1.0

    // MARK: - Audio Playback Manager Integration
    @StateObject private var audioManager = AudioPlaybackManager()
    
    // Speed options.
    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    // Available language names.
    var availableLanguageNames: [String] {
        book.languages.map { $0.name }
    }
    var availableLanguagesWithNone: [String] {
        ["None"] + availableLanguageNames
    }

    // Computed property: returns the code for the primary selected language.
    private var selectedLanguage1Code: String {
        return LanguageCode.allCases.first(where: { $0.name == selectedLanguage1 })?.rawValue ?? "en-US"
    }
    
    // Helper computed properties for secondary and tertiary language codes.
    private var selectedLanguage2Code: String? {
        if selectedLanguage2 != "None" {
            return LanguageCode.allCases.first(where: { $0.name == selectedLanguage2 })?.rawValue
        }
        return nil
    }
    private var selectedLanguage3Code: String? {
        if selectedLanguage3 != "None" {
            return LanguageCode.allCases.first(where: { $0.name == selectedLanguage3 })?.rawValue
        }
        return nil
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
    
    var totalSentences: Int {
        chapterContent?.paragraphs.reduce(0) { $0 + $1.sentences.count } ?? 0
    }
    
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
    
    var maxSliderValue: Double {
        totalSentences > 0 ? Double(totalSentences - 1) : 0.0
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Subbook Picker
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
                    // Chapter Picker
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
                    // Sentence Display
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
                    // Playback Controls
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
                                audioManager.pause()
                                audioManager.onPlaybackFinished = nil
                                print("[Play/Pause] Pausing playback. Stage: \(currentPlaybackStage)")
                                didPause = true
                            } else if !isAtEnd {
                                if didPause {
                                    print("[Play/Pause] Resuming playback from paused state. Stage: \(currentPlaybackStage)")
                                    isPlaying = true
                                    // Reattach the onPlaybackFinished callback
                                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                                    audioManager.play()
                                } else {
                                    print("[Play/Pause] Starting playback. Stage: \(currentPlaybackStage), setting speed for current stage.")
                                    isPlaying = true
                                    if let sentence = sentenceForCurrentStage() {
                                        audioManager.loadAudio(for: sentence)
                                        if currentPlaybackStage == 1 {
                                            audioManager.setRate(Float(selectedSpeed1))
                                        } else if currentPlaybackStage == 2 {
                                            audioManager.setRate(Float(selectedSpeed2))
                                        } else if currentPlaybackStage == 3 {
                                            audioManager.setRate(Float(selectedSpeed3))
                                        }
                                    }
                                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                                    audioManager.play()
                                }
                                didPause = false
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
                    // Slider for Chapter Navigation
                    Slider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                sliderValue = newValue
                                let targetIndex = Int(round(newValue))
                                currentSentenceIndex = targetIndex
                                if let sentence = chapterContent.flatMap({ getCurrentSentence(from: $0, at: targetIndex) }) {
                                    currentSentence = sentence.text
                                    audioManager.loadAudio(for: sentence)
                                    if isPlaying {
                                        // Immediately reapply the correct rate after reloading audio.
                                        if currentPlaybackStage == 1 {
                                            audioManager.setRate(Float(selectedSpeed1))
                                        } else if currentPlaybackStage == 2 {
                                            audioManager.setRate(Float(selectedSpeed2))
                                        } else if currentPlaybackStage == 3 {
                                            audioManager.setRate(Float(selectedSpeed3))
                                        }
                                        audioManager.play()
                                    }
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
                    // Playback Options: Language and Speed Pickers
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
                chapterContent = loadChapterContent(language: selectedLanguage1Code)
                
                // Validate selectedChapterIndex: if it's out of range, reset it to 0.
                if let chaptersCount = chapterContent?.paragraphs.first?.sentences.count, // or use selectedSubBook.chapters.count if available
                   selectedChapterIndex >= selectedSubBook.chapters.count {
                    selectedChapterIndex = 0
                }
                
                currentSentenceIndex = bookState?.lastGlobalSentenceIndex ?? 0
                sliderValue = 0.0
                if let content = chapterContent,
                   let sentence = getCurrentSentence(from: content, at: currentSentenceIndex) {
                    currentSentence = sentence.text
                }
                print("[onAppear] Setting primary speed to \(selectedSpeed1)")
                audioManager.setRate(Float(selectedSpeed1))
                DispatchQueue.main.async {
                    hasRestoredState = true
                }
            }
            .onDisappear {
                saveBookState()
                updateGlobalAppStateForBookDetail()
                audioManager.pause()
                audioManager.onPlaybackFinished = nil
            }
        }
        .navigationTitle(book.bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        // onChange Handlers for indices
        .onChange(of: selectedSubBookIndex) { _, _ in
            if hasRestoredState && !internalNavigation {
                isPlaying = false
                audioManager.pause()
                audioManager.onPlaybackFinished = nil
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
            }
        }
        .onChange(of: selectedChapterIndex) { _, _ in
            if hasRestoredState && !internalNavigation {
                isPlaying = false
                audioManager.pause()
                audioManager.onPlaybackFinished = nil
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
            }
        }
        // onChange Handlers for language selectors
        .onChange(of: selectedLanguage1) {
            let languageCode = selectedLanguage1Code
            chapterContent = loadChapterContent(language: languageCode)
            if let content = chapterContent,
               let sentence = getCurrentSentence(from: content, at: currentSentenceIndex) {
                currentSentence = sentence.text
            } else {
                currentSentence = "No sentence available."
            }
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
            if currentPlaybackStage == 1 {
                audioManager.setRate(Float(selectedSpeed1))
                print("[Speed] Primary speed updated to \(selectedSpeed1)")
            }
        }
        .onChange(of: selectedSpeed2) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            if currentPlaybackStage == 2 {
                audioManager.setRate(Float(selectedSpeed2))
                print("[Speed] Primary speed updated to \(selectedSpeed2)")
            }
        }
        .onChange(of: selectedSpeed3) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            if currentPlaybackStage == 3 {
                audioManager.setRate(Float(selectedSpeed3))
                print("[Speed] Primary speed updated to \(selectedSpeed3)")
            }
        }
    }
    
    // MARK: - Helper: Get Sentence for Current Stage
    private func sentenceForCurrentStage() -> SentenceContent? {
        if currentPlaybackStage == 1 {
            return currentSentenceContent()
        } else if currentPlaybackStage == 2, let _ = selectedLanguage2Code {
            let content = loadChapterContent(language: selectedLanguage2Code!)
            return content.flatMap { getCurrentSentence(from: $0, at: currentSentenceIndex) }
        } else if currentPlaybackStage == 3, let _ = selectedLanguage3Code {
            let content = loadChapterContent(language: selectedLanguage3Code!)
            return content.flatMap { getCurrentSentence(from: $0, at: currentSentenceIndex) }
        }
        return nil
    }
    
    // MARK: - Audio Completion Handler
    private func audioDidFinishPlaying() {
        guard isPlaying else { return }
        
        if currentPlaybackStage == 1 {
            if let lang2 = selectedLanguage2Code,
               let content2 = loadChapterContent(language: lang2),
               let sentence2 = getCurrentSentence(from: content2, at: currentSentenceIndex) {
                currentSentence = sentence2.text
                audioManager.loadAudio(for: sentence2)
                currentPlaybackStage = 2
                audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                audioManager.setRate(Float(selectedSpeed2))
                audioManager.play()
                return
            }
            if let lang3 = selectedLanguage3Code,
               let content3 = loadChapterContent(language: lang3),
               let sentence3 = getCurrentSentence(from: content3, at: currentSentenceIndex) {
                currentSentence = sentence3.text
                audioManager.loadAudio(for: sentence3)
                currentPlaybackStage = 3
                audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                audioManager.setRate(Float(selectedSpeed3))
                audioManager.play()
                return
            }
            advanceSentenceWithReset()
        } else if currentPlaybackStage == 2 {
            if let lang3 = selectedLanguage3Code,
               let content3 = loadChapterContent(language: lang3),
               let sentence3 = getCurrentSentence(from: content3, at: currentSentenceIndex) {
                currentSentence = sentence3.text
                audioManager.loadAudio(for: sentence3)
                currentPlaybackStage = 3
                audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                audioManager.setRate(Float(selectedSpeed3))
                audioManager.play()
                return
            }
            advanceSentenceWithReset()
        } else if currentPlaybackStage == 3 {
            advanceSentenceWithReset()
        }
    }
    
    // MARK: - Helper: Get Current SentenceContent (primary language)
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
            if isPlaying { audioManager.play() }
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
            if isPlaying { audioManager.play() }
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    // MARK: - Advance Sentence When Audio Finishes (with reset)
    private func advanceSentenceWithReset() {
        currentPlaybackStage = 1
        advanceSentence()
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
                    audioManager.setRate(Float(selectedSpeed1))
                    audioManager.play()
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                }
            }
        } else {
            if selectedChapterIndex < selectedSubBook.chapters.count - 1 {
                internalNavigation = true
                selectedChapterIndex += 1
            } else if selectedSubBookIndex < book.subBooks.count - 1 {
                internalNavigation = true
                selectedSubBookIndex += 1
                selectedChapterIndex = 0
            } else {
                isPlaying = false
                return
            }
            currentSentenceIndex = 0
            sliderValue = 0.0
            chapterContent = loadChapterContent(language: selectedLanguage1Code)
            currentPlaybackStage = 1
            if let newContent = chapterContent,
               let firstSentence = getCurrentSentence(from: newContent, at: 0) {
                currentSentence = firstSentence.text
                audioManager.loadAudio(for: firstSentence)
                if isPlaying {
                    audioManager.setRate(Float(selectedSpeed1))
                    audioManager.play()
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.internalNavigation = false
            }
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    // MARK: - Update Current Sentence on Selection Change
    private func updateCurrentSentenceForSelection() {
        chapterContent = loadChapterContent(language: selectedLanguage1Code)
        currentSentenceIndex = 0
        sliderValue = 0.0
        if let content = chapterContent,
           let firstSentence = getCurrentSentence(from: content, at: 0) {
            currentSentence = firstSentence.text
        } else {
            currentSentence = "No sentence available."
        }
    }
    
    // MARK: - JSON Parsing Helpers
    private func chapterJSONFileName(language: String) -> String {
        let bookCode = book.bookCode
        let subNumber = selectedSubBook.subBookNumber
        let chapterNum = selectedChapter.chapterNumber
        return "\(bookCode)_S\(subNumber)_C\(chapterNum)_\(language).json"
    }
    
    private func loadChapterContent(language: String = "en-US") -> ChapterContent? {
        let fileName = chapterJSONFileName(language: language)
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
