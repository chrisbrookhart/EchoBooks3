//
//  BookDetailView.swift
//  EchoBooks3
// 
//  Updated to use ContentLoader for new format books.
//  Removed all old format loading code.
//
import SwiftUI
import SwiftData
import UIKit

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext

    // MARK: - Navigation & Content State
    @State private var selectedSubBookIndex: Int = 0
    @State private var selectedChapterIndex: Int = 0
    @State private var showingNavigationSheet: Bool = false
    @State private var showSettings: Bool = false

    // MARK: - Content Display & Playback State
    @State private var currentSentence: String = "Loading sentence..."
    @State private var sliderNormalized: Double = 0.0
    @State private var isPlaying: Bool = false
    // globalSentenceIndex represents the chapter-level cumulative index.
    @State private var globalSentenceIndex: Int = 0

    /// Playback stage:
    /// 1 = primary language,
    /// 2 = secondary,
    /// 3 = tertiary.
    @State private var currentPlaybackStage: Int = 1

    /// Flag to indicate if chapter/subbook change is internal.
    @State private var internalNavigation: Bool = false

    /// Flag to track if playback was paused.
    @State private var didPause: Bool = false

    // MARK: - Global Playback Settings (via @AppStorage)
    @AppStorage("selectedLanguage1") private var selectedLanguage1: String = "en-US"
    @AppStorage("selectedLanguage2") private var selectedLanguage2: String = "None"
    @AppStorage("selectedLanguage3") private var selectedLanguage3: String = "None"
    
    @AppStorage("selectedSpeed1") private var selectedSpeed1: Double = 1.0
    @AppStorage("selectedSpeed2") private var selectedSpeed2: Double = 1.0
    @AppStorage("selectedSpeed3") private var selectedSpeed3: Double = 1.0
    
    /// Global playback mode – "Sentence" or "Paragraph".
    @AppStorage("playbackMode") private var playbackMode: String = PlaybackMode.sentence.rawValue

    // MARK: - Audio Playback Manager Integration
    @StateObject private var audioManager = AudioPlaybackManager()
    
    // MARK: - Content Loader
    @State private var contentLoader: ContentLoader?
    
    // Speed options.
    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    // Available language names from the book.
    var availableLanguageNames: [String] {
        book.languages.map { $0.name }
    }
    var availableLanguagesWithNone: [String] {
        ["None"] + availableLanguageNames
    }
    
    // Computed property for primary language code.
    private var selectedLanguage1Code: String {
        return selectedLanguage1
    }
    
    // Helper computed properties for secondary and tertiary language codes.
    private var selectedLanguage2Code: String? {
        if selectedLanguage2 != "None" { return selectedLanguage2 }
        return nil
    }
    private var selectedLanguage3Code: String? {
        if selectedLanguage3 != "None" { return selectedLanguage3 }
        return nil
    }
    
    // Convenience computed properties.
    var selectedSubBook: SubBook {
        book.effectiveSubBooks[selectedSubBookIndex]
    }
    var selectedChapter: Chapter {
        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
            return selectedSubBook.chapters.first!
        }
        return selectedSubBook.chapters[selectedChapterIndex]
    }
    
    // MARK: - Persistence State (Book-specific)
    @State private var bookState: BookState?
    
    // MARK: - Chapter Content State (New Format)
    @State private var chapterSentences: [SentenceData] = []
    @State private var chapterParagraphs: [ParagraphData] = []
    
    var totalSentences: Int {
        chapterSentences.count
    }
    
    private var isAtEnd: Bool {
        let atEndOfChapter = globalSentenceIndex >= chapterSentences.count - 1
        let isLastChapter = selectedChapterIndex == (selectedSubBook.chapters.count - 1)
        let isLastSubBook = selectedSubBookIndex == (book.effectiveSubBooks.count - 1)
        return atEndOfChapter && isLastChapter && isLastSubBook
    }
    
    // MARK: - Initial Restoration Flag
    @State private var hasRestoredState: Bool = false
    
    // The slider now uses a normalized value between 0 and 1.
    var maxSliderNormalized: Double { 1.0 }
    
    // MARK: - Paragraph Mode Helpers
    
    /// Returns (paragraph index, local index) for a given global sentence index in a chapter.
    private func paragraphIndices(for globalIndex: Int) -> (paragraphIndex: Int, localIndex: Int)? {
        guard globalIndex < chapterSentences.count else { return nil }
        let sentence = chapterSentences[globalIndex]
        
        // Find the paragraph this sentence belongs to
        guard let paragraphIndex = chapterParagraphs.firstIndex(where: { $0.paragraphId == sentence.paragraphId }) else {
            return nil
        }
        
        // Find the local index within that paragraph
        let paragraphSentences = chapterSentences.filter { $0.paragraphId == sentence.paragraphId }
            .sorted { $0.sentenceIndexInParagraph < $1.sentenceIndexInParagraph }
        
        guard let localIndex = paragraphSentences.firstIndex(where: { $0.sentenceId == sentence.sentenceId }) else {
            return nil
        }
        
        return (paragraphIndex, localIndex)
    }
    
    /// Returns the global index of the first sentence in the next paragraph, if it exists.
    private func nextParagraphGlobalIndex(after globalIndex: Int) -> Int? {
        guard globalIndex < chapterSentences.count else { return nil }
        let currentSentence = chapterSentences[globalIndex]
        
        // Find current paragraph index
        guard let currentParagraphIndex = chapterParagraphs.firstIndex(where: { $0.paragraphId == currentSentence.paragraphId }) else {
            return nil
        }
        
        // Check if there's a next paragraph
        guard currentParagraphIndex < chapterParagraphs.count - 1 else {
            return nil
        }
        
        let nextParagraph = chapterParagraphs[currentParagraphIndex + 1]
        // Find first sentence of next paragraph
        if let firstSentence = chapterSentences.first(where: { $0.paragraphId == nextParagraph.paragraphId }) {
            return chapterSentences.firstIndex(where: { $0.sentenceId == firstSentence.sentenceId })
        }
        
        return nil
    }
    
    /// Returns the global index of the first sentence in the paragraph containing the given global index.
    private func paragraphStartIndex(for globalIndex: Int) -> Int? {
        guard globalIndex < chapterSentences.count else { return nil }
        let sentence = chapterSentences[globalIndex]
        
        // Find first sentence in the same paragraph
        let paragraphSentences = chapterSentences.filter { $0.paragraphId == sentence.paragraphId }
            .sorted { $0.sentenceIndexInParagraph < $1.sentenceIndexInParagraph }
        
        guard let firstSentence = paragraphSentences.first else { return nil }
        return chapterSentences.firstIndex(where: { $0.sentenceId == firstSentence.sentenceId })
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // "Select Chapter" Button.
                    Button(action: { showingNavigationSheet = true }) {
                        HStack {
                            if selectedSubBook.subBookTitle.lowercased() == "default" {
                                Text(selectedChapter.chapterTitle)
                                    .font(DesignSystem.Typography.h3)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            } else {
                                Text("\(selectedSubBook.subBookTitle) \(selectedChapter.chapterTitle)")
                                    .font(DesignSystem.Typography.h3)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(DesignSystem.Typography.label)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .shadow(DesignSystem.Shadow.small)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    
                    // Enlarged Sentence Display Area.
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.gradientStart,
                                DesignSystem.Colors.gradientEnd
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Text(currentSentence)
                            .font(DesignSystem.Typography.sentenceDisplay)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(DesignSystem.Spacing.sm)
                            .padding(DesignSystem.Spacing.lg)
                    }
                    .frame(height: geo.size.height * 0.65)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(DesignSystem.Shadow.medium)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    
                    // Playback Controls.
                    HStack {
                        Spacer()
                        Button(action: { skipBackwardAction() }) {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .font(.system(size: DesignSystem.Layout.playbackControlSize))
                        }
                        .disabled(globalSentenceIndex == 0)
                        .foregroundColor(globalSentenceIndex == 0 ? DesignSystem.Colors.interactiveDisabled : DesignSystem.Colors.primary)
                        Spacer()
                        Button(action: {
                            if isPlaying {
                                isPlaying = false
                                audioManager.pause()
                                audioManager.onPlaybackFinished = nil
                                didPause = true
                            } else if !isAtEnd {
                                if didPause {
                                    isPlaying = true
                                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                                    audioManager.play()
                                } else {
                                    isPlaying = true
                                    if let sentenceId = getCurrentSentenceId() {
                                        let languageCode = getLanguageCodeForCurrentStage()
                                        audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: languageCode)
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
                                .font(.system(size: DesignSystem.Layout.playbackButtonSize))
                        }
                        .foregroundColor(isAtEnd ? DesignSystem.Colors.interactiveDisabled : DesignSystem.Colors.primary)
                        .disabled(isAtEnd)
                        Spacer()
                        Button(action: { skipForwardAction() }) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .font(.system(size: DesignSystem.Layout.playbackControlSize))
                        }
                        .disabled(isAtEnd)
                        .foregroundColor(isAtEnd ? DesignSystem.Colors.interactiveDisabled : DesignSystem.Colors.primary)
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    
                    // Normalized Slider for Chapter Navigation.
                    Slider(
                        value: Binding(
                            get: { sliderNormalized },
                            set: { newValue in
                                sliderNormalized = newValue
                                let computedIndex = Int(round(newValue * Double(totalSentences - 1)))
                                globalSentenceIndex = computedIndex
                                if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code) {
                                    currentSentence = sentenceText
                                    if let sentenceId = getCurrentSentenceId() {
                                        audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
                                        if isPlaying {
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
                                }
                                let computedSlider = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                                print("DEBUG: [Slider Update] totalSentences = \(totalSentences), globalSentenceIndex = \(globalSentenceIndex), computed normalized slider = \(computedSlider)")
                                saveBookState()
                                updateGlobalAppStateForBookDetail()
                            }
                        ),
                        in: 0...maxSliderNormalized,
                        onEditingChanged: { _ in
                            saveBookState()
                            updateGlobalAppStateForBookDetail()
                        }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            // Modal Sheet for Subbook/Chapter Selection.
            .sheet(isPresented: $showingNavigationSheet) {
                NavigationStack {
                    Form {
                        if book.effectiveSubBooks.count > 1 && book.effectiveSubBooks.first?.subBookTitle.lowercased() != "default" {
                            HStack {
                                Spacer()
                                Picker("", selection: $selectedSubBookIndex) {
                                    ForEach(0..<book.effectiveSubBooks.count, id: \.self) { index in
                                        Text(book.effectiveSubBooks[index].subBookTitle).tag(index)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                Spacer()
                            }
                        }
                        HStack {
                            Spacer()
                            Picker("", selection: $selectedChapterIndex) {
                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
                                    Text(selectedSubBook.chapters[index].chapterTitle).tag(index)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingNavigationSheet = false
                                updateCurrentSentenceForSelection()
                            }
                            .font(DesignSystem.Typography.button)
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .onAppear {
                loadBookState()
                updateGlobalAppStateForBookDetail()
                initializeContentLoader()
                loadChapterContent()
                if selectedChapterIndex >= selectedSubBook.chapters.count {
                    selectedChapterIndex = 0
                }
                globalSentenceIndex = bookState?.lastGlobalSentenceIndex ?? 0
                sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code) {
                    currentSentence = sentenceText
                }
                audioManager.setRate(Float(selectedSpeed1))
                print("DEBUG onAppear: totalSentences = \(totalSentences), globalSentenceIndex = \(globalSentenceIndex), sliderNormalized = \(sliderNormalized)")
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
        .toolbar {
            // Settings gear remains in the navigation bar.
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(availableLanguages: book.languages)
        }
        .onChange(of: selectedSubBookIndex) { _, newValue in
            // Always update immediately when subbook changes (unless it's internal navigation)
            if !internalNavigation {
                isPlaying = false
                audioManager.pause()
                audioManager.onPlaybackFinished = nil
                // Reset chapter index when subbook changes
                selectedChapterIndex = 0
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else {
                // Reset internalNavigation flag after internal navigation completes
                internalNavigation = false
            }
        }
        .onChange(of: selectedChapterIndex) { _, newValue in
            // Always update immediately when chapter changes (unless it's internal navigation)
            if !internalNavigation {
                isPlaying = false
                audioManager.pause()
                audioManager.onPlaybackFinished = nil
                updateCurrentSentenceForSelection()
                saveBookState()
                updateGlobalAppStateForBookDetail()
            } else {
                // Reset internalNavigation flag after internal navigation completes
                internalNavigation = false
            }
        }
        .onChange(of: selectedLanguage1) {
            loadChapterContent()
            if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code) {
                currentSentence = sentenceText
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
            }
        }
        .onChange(of: selectedSpeed2) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            if currentPlaybackStage == 2 {
                audioManager.setRate(Float(selectedSpeed2))
            }
        }
        .onChange(of: selectedSpeed3) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
            if currentPlaybackStage == 3 {
                audioManager.setRate(Float(selectedSpeed3))
            }
        }
    }
    
    // MARK: - Content Loading (New Format)
    
    /// Initializes the ContentLoader for this book
    private func initializeContentLoader() {
        if contentLoader == nil {
            contentLoader = ContentLoader(bookCode: book.bookCode)
        }
    }
    
    /// Loads chapter content using ContentLoader
    private func loadChapterContent() {
        guard let loader = contentLoader else {
            initializeContentLoader()
            guard let loader = contentLoader else { return }
            loadChapterContentWithLoader(loader)
            return
        }
        loadChapterContentWithLoader(loader)
    }
    
    private func loadChapterContentWithLoader(_ loader: ContentLoader) {
        do {
            let chapterIndex = selectedChapter.chapterNumber
            chapterSentences = try loader.sentences(for: chapterIndex)
            chapterParagraphs = try loader.paragraphs(for: chapterIndex)
            
            // Sort sentences by their index in paragraph to maintain order
            chapterSentences.sort { s1, s2 in
                if s1.paragraphId != s2.paragraphId {
                    // First sort by paragraph order
                    guard let p1Index = chapterParagraphs.firstIndex(where: { $0.paragraphId == s1.paragraphId }),
                          let p2Index = chapterParagraphs.firstIndex(where: { $0.paragraphId == s2.paragraphId }) else {
                        return false
                    }
                    if p1Index != p2Index {
                        return p1Index < p2Index
                    }
                }
                // Then by sentence index within paragraph
                return s1.sentenceIndexInParagraph < s2.sentenceIndexInParagraph
            }
        } catch {
            print("ERROR: Failed to load chapter content: \(error)")
            chapterSentences = []
            chapterParagraphs = []
        }
    }
    
    // MARK: - Helper: Get Sentence Data
    
    /// Gets the current sentence ID
    private func getCurrentSentenceId() -> String? {
        guard globalSentenceIndex < chapterSentences.count else { return nil }
        return chapterSentences[globalSentenceIndex].sentenceId
    }
    
    /// Gets the current sentence text in the specified language
    private func getCurrentSentenceText(languageCode: String) -> String? {
        guard globalSentenceIndex < chapterSentences.count else { return nil }
        let sentenceData = chapterSentences[globalSentenceIndex]
        
        // Check if this is the primary language (simplified format uses primary language text)
        let normalizedLang = normalizeLanguageCode(languageCode)
        let primaryLang = normalizeLanguageCode(selectedLanguage1Code)
        
        if normalizedLang == primaryLang {
            // Use the text from SentenceData (primary language)
            return sentenceData.text
        } else {
            // Get translation from ContentLoader
            guard let loader = contentLoader else { return sentenceData.text }
            do {
                if let translation = try loader.translation(for: sentenceData.sentenceId, languageCode: languageCode) {
                    return translation
                }
            } catch {
                print("ERROR: Failed to get translation: \(error)")
            }
            return sentenceData.text
        }
    }
    
    /// Normalizes a language code to its simplified form
    private func normalizeLanguageCode(_ code: String) -> String {
        if !code.contains("-") {
            return code.lowercased()
        }
        let components = code.split(separator: "-")
        return String(components[0]).lowercased()
    }
    
    // MARK: - Helper: Get Language Code for Current Stage
    private func getLanguageCodeForCurrentStage() -> String {
        if currentPlaybackStage == 1 {
            return selectedLanguage1Code
        } else if currentPlaybackStage == 2, let lang2 = selectedLanguage2Code {
            return lang2
        } else if currentPlaybackStage == 3, let lang3 = selectedLanguage3Code {
            return lang3
        }
        return selectedLanguage1Code
    }
    
    // MARK: - Audio Completion Handler
    private func audioDidFinishPlaying() {
        guard isPlaying else { return }
        
        if playbackMode == PlaybackMode.paragraph.rawValue {
            // In Paragraph mode:
            if let indices = paragraphIndices(for: globalSentenceIndex) {
                let paragraphId = chapterSentences[globalSentenceIndex].paragraphId
                let paragraphSentences = chapterSentences.filter { $0.paragraphId == paragraphId }
                    .sorted { $0.sentenceIndexInParagraph < $1.sentenceIndexInParagraph }
                
                if indices.localIndex < paragraphSentences.count - 1 {
                    // Advance to the next sentence within the same paragraph.
                    globalSentenceIndex += 1
                    sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                    if let sentenceText = getCurrentSentenceText(languageCode: getLanguageCodeForCurrentStage()) {
                        currentSentence = sentenceText
                        if let sentenceId = getCurrentSentenceId() {
                            let languageCode = getLanguageCodeForCurrentStage()
                            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: languageCode)
                            if currentPlaybackStage == 1 {
                                audioManager.setRate(Float(selectedSpeed1))
                            } else if currentPlaybackStage == 2 {
                                audioManager.setRate(Float(selectedSpeed2))
                            } else if currentPlaybackStage == 3 {
                                audioManager.setRate(Float(selectedSpeed3))
                            }
                            print("DEBUG: Paragraph mode - Advanced within paragraph: globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(totalSentences), sliderNormalized = \(sliderNormalized)")
                            audioManager.play()
                            return
                        }
                    }
                } else {
                    // End of paragraph reached.
                    // Switch to the next language if available.
                    if currentPlaybackStage == 1, selectedLanguage2 != "None" {
                        // Reset to start of paragraph for language 2
                        if let startIndex = paragraphStartIndex(for: globalSentenceIndex) {
                            globalSentenceIndex = startIndex
                            sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                            print("DEBUG: Paragraph mode - End of paragraph reached; reset globalSentenceIndex to \(globalSentenceIndex) for language 2")
                        }
                        if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage2),
                           let sentenceId = getCurrentSentenceId() {
                            currentSentence = sentenceText
                            currentPlaybackStage = 2
                            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage2)
                            audioManager.setRate(Float(selectedSpeed2))
                            print("DEBUG: Paragraph mode - Switching to secondary language at globalSentenceIndex = \(globalSentenceIndex)")
                            audioManager.play()
                            return
                        }
                    } else if currentPlaybackStage == 2, selectedLanguage3 != "None" {
                        // Reset to start of paragraph for language 3
                        if let startIndex = paragraphStartIndex(for: globalSentenceIndex) {
                            globalSentenceIndex = startIndex
                            sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                            print("DEBUG: Paragraph mode - End of paragraph reached; reset globalSentenceIndex to \(globalSentenceIndex) for language 3")
                        }
                        if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage3),
                           let sentenceId = getCurrentSentenceId() {
                            currentSentence = sentenceText
                            currentPlaybackStage = 3
                            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage3)
                            audioManager.setRate(Float(selectedSpeed3))
                            print("DEBUG: Paragraph mode - Switching to tertiary language at globalSentenceIndex = \(globalSentenceIndex)")
                            audioManager.play()
                            return
                        }
                    }
                    
                    // All languages have played for this paragraph. Advance to next paragraph.
                    // IMPORTANT: Don't reset globalSentenceIndex here - we want to advance to the next paragraph
                    loadChapterContent()
                    if let nextParagraphStart = nextParagraphGlobalIndex(after: globalSentenceIndex) {
                        // Get the sentence ID for the next paragraph start, not the current (reset) index
                        let savedIndex = globalSentenceIndex
                        globalSentenceIndex = nextParagraphStart
                        sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                        currentPlaybackStage = 1
                        if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code),
                           let sentenceId = getCurrentSentenceId() {
                            currentSentence = sentenceText
                            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
                            audioManager.setRate(Float(selectedSpeed1))
                            print("DEBUG: Paragraph mode - Advancing to next paragraph: from index \(savedIndex) to \(globalSentenceIndex), totalSentences = \(totalSentences), sliderNormalized = \(sliderNormalized)")
                            audioManager.play()
                            return
                        }
                    } else {
                        // No next paragraph exists in the current chapter;
                        advanceToNextChapterOrSubBook()
                        return
                    }
                }
            }
        } else {
            // Sentence mode: existing behavior.
            if currentPlaybackStage == 1 {
                if let lang2 = selectedLanguage2Code,
                   let sentenceText = getCurrentSentenceText(languageCode: lang2),
                   let sentenceId = getCurrentSentenceId() {
                    currentSentence = sentenceText
                    audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: lang2)
                    currentPlaybackStage = 2
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                    audioManager.setRate(Float(selectedSpeed2))
                    print("DEBUG: Sentence mode - Switching to secondary language at globalSentenceIndex = \(globalSentenceIndex)")
                    audioManager.play()
                    return
                }
                if let lang3 = selectedLanguage3Code,
                   let sentenceText = getCurrentSentenceText(languageCode: lang3),
                   let sentenceId = getCurrentSentenceId() {
                    currentSentence = sentenceText
                    audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: lang3)
                    currentPlaybackStage = 3
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                    audioManager.setRate(Float(selectedSpeed3))
                    print("DEBUG: Sentence mode - Switching to tertiary language at globalSentenceIndex = \(globalSentenceIndex)")
                    audioManager.play()
                    return
                }
                advanceSentenceWithReset()
            } else if currentPlaybackStage == 2 {
                if let lang3 = selectedLanguage3Code,
                   let sentenceText = getCurrentSentenceText(languageCode: lang3),
                   let sentenceId = getCurrentSentenceId() {
                    currentSentence = sentenceText
                    audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: lang3)
                    currentPlaybackStage = 3
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                    audioManager.setRate(Float(selectedSpeed3))
                    print("DEBUG: Sentence mode - Switching from secondary to tertiary at globalSentenceIndex = \(globalSentenceIndex)")
                    audioManager.play()
                    return
                }
                advanceSentenceWithReset()
            } else if currentPlaybackStage == 3 {
                advanceSentenceWithReset()
            }
        }
    }
    
    // MARK: - Skip Button Actions
    private func skipBackwardAction() {
        let total = chapterSentences.count
        let newIndex = max(globalSentenceIndex - 5, 0)
        globalSentenceIndex = newIndex
        sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
        if let sentenceText = getCurrentSentenceText(languageCode: getLanguageCodeForCurrentStage()) {
            currentSentence = sentenceText
            if let sentenceId = getCurrentSentenceId() {
                let languageCode = getLanguageCodeForCurrentStage()
                audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: languageCode)
                if isPlaying { audioManager.play() }
            }
        }
        print("DEBUG: Skip Backward - globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(total), sliderNormalized = \(sliderNormalized)")
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    private func skipForwardAction() {
        let total = chapterSentences.count
        let newIndex = min(globalSentenceIndex + 5, total - 1)
        globalSentenceIndex = newIndex
        sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
        if let sentenceText = getCurrentSentenceText(languageCode: getLanguageCodeForCurrentStage()) {
            currentSentence = sentenceText
            if let sentenceId = getCurrentSentenceId() {
                let languageCode = getLanguageCodeForCurrentStage()
                audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: languageCode)
                if isPlaying { audioManager.play() }
            }
        }
        print("DEBUG: Skip Forward - globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(total), sliderNormalized = \(sliderNormalized)")
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    // MARK: - Advance Sentence When Audio Finishes (with reset)
    private func advanceSentenceWithReset() {
        currentPlaybackStage = 1
        advanceSentence()
    }
    
    private func advanceSentence() {
        let total = chapterSentences.count
        if globalSentenceIndex < total - 1 {
            globalSentenceIndex += 1
            sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
            if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code),
               let sentenceId = getCurrentSentenceId() {
                currentSentence = sentenceText
                audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
                if isPlaying {
                    audioManager.setRate(Float(selectedSpeed1))
                    audioManager.play()
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                }
                print("DEBUG: Advance Sentence - globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(total), sliderNormalized = \(sliderNormalized)")
            }
        } else {
            // End of chapter content.
            if selectedChapterIndex < selectedSubBook.chapters.count - 1 {
                internalNavigation = true
                selectedChapterIndex += 1
                print("DEBUG: Advance Sentence - transitioning to next chapter")
            } else if selectedSubBookIndex < book.effectiveSubBooks.count - 1 {
                internalNavigation = true
                selectedSubBookIndex += 1
                selectedChapterIndex = 0
                print("DEBUG: Advance Sentence - transitioning to next subbook")
            } else {
                isPlaying = false
                print("DEBUG: Advance Sentence - reached end of book")
                return
            }
            globalSentenceIndex = 0
            sliderNormalized = 0.0
            loadChapterContent()
            currentPlaybackStage = 1
            if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code),
               let sentenceId = getCurrentSentenceId() {
                currentSentence = sentenceText
                audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
                if isPlaying {
                    audioManager.setRate(Float(selectedSpeed1))
                    audioManager.play()
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                }
                print("DEBUG: Advance Sentence - new chapter loaded, globalSentenceIndex reset to \(globalSentenceIndex)")
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
        loadChapterContent()
        globalSentenceIndex = 0
        sliderNormalized = 0.0
        currentPlaybackStage = 1  // Reset to primary language
        
        if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code) {
            currentSentence = sentenceText
        } else {
            currentSentence = "No sentence available."
        }
        
        // Load the audio for the first sentence of the new chapter
        if let sentenceId = getCurrentSentenceId() {
            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
            audioManager.setRate(Float(selectedSpeed1))
            // Don't auto-play - let the user decide when to play
        }
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
            sliderNormalized = state.lastSliderValue
            globalSentenceIndex = state.lastGlobalSentenceIndex
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
        state.lastSliderValue = sliderNormalized
        state.lastGlobalSentenceIndex = globalSentenceIndex
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
    
    // MARK: - Helper: Chapter/Subbook Transition
    private func advanceToNextChapterOrSubBook() {
        if selectedChapterIndex < selectedSubBook.chapters.count - 1 {
            internalNavigation = true
            selectedChapterIndex += 1
            print("DEBUG: Transitioning to next chapter.")
        } else if selectedSubBookIndex < book.effectiveSubBooks.count - 1 {
            internalNavigation = true
            selectedSubBookIndex += 1
            selectedChapterIndex = 0
            print("DEBUG: Transitioning to next subbook.")
        } else {
            isPlaying = false
            print("DEBUG: End of book reached.")
            return
        }
        globalSentenceIndex = 0
        sliderNormalized = 0.0
        loadChapterContent()
        currentPlaybackStage = 1
        if let sentenceText = getCurrentSentenceText(languageCode: selectedLanguage1Code),
           let sentenceId = getCurrentSentenceId() {
            currentSentence = sentenceText
            audioManager.loadAudio(sentenceId: sentenceId, bookCode: book.bookCode, languageCode: selectedLanguage1Code)
            if isPlaying {
                audioManager.setRate(Float(selectedSpeed1))
                audioManager.play()
                audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
            }
            print("DEBUG: New chapter loaded. globalSentenceIndex reset to \(globalSentenceIndex)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.internalNavigation = false
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
}
