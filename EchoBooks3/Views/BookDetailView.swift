//
//  BookDetailView.swift
//  EchoBooks3
//
//  Revised to use global settings for language and speed selections,
//  and to support two playback modes: "Sentence" (default) and "Paragraph".
//  In Paragraph mode the app plays an entire paragraph in one language,
//  then replays the paragraph in the next language (if available),
//  before advancing to the next paragraph (or chapter/subbook).
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
        book.subBooks[selectedSubBookIndex]
    }
    var selectedChapter: Chapter {
        guard selectedSubBook.chapters.indices.contains(selectedChapterIndex) else {
            return selectedSubBook.chapters.first!
        }
        return selectedSubBook.chapters[selectedChapterIndex]
    }
    
    // MARK: - Persistence State (Book-specific)
    @State private var bookState: BookState?
    
    // MARK: - Chapter Content State
    @State private var chapterContent: ChapterContent?
    
    var totalSentences: Int {
        chapterContent?.paragraphs.reduce(0) { $0 + $1.sentences.count } ?? 0
    }
    
    private var isAtEnd: Bool {
        guard let content = chapterContent else { return true }
        let totalSentencesInChapter = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let atEndOfChapter = globalSentenceIndex >= totalSentencesInChapter - 1
        let isLastChapter = selectedChapterIndex == (selectedSubBook.chapters.count - 1)
        let isLastSubBook = selectedSubBookIndex == (book.subBooks.count - 1)
        return atEndOfChapter && isLastChapter && isLastSubBook
    }
    
    // MARK: - Initial Restoration Flag
    @State private var hasRestoredState: Bool = false
    
    // The slider now uses a normalized value between 0 and 1.
    var maxSliderNormalized: Double { 1.0 }
    
    // MARK: - Paragraph Mode Helpers (defined as private methods)
    
    /// Returns (paragraph index, local index) for a given global sentence index in a chapter.
    private func paragraphIndices(for globalIndex: Int, in chapter: ChapterContent) -> (paragraphIndex: Int, localIndex: Int)? {
        var runningIndex = 0
        for (i, paragraph) in chapter.paragraphs.enumerated() {
            let count = paragraph.sentences.count
            if globalIndex < runningIndex + count {
                return (i, globalIndex - runningIndex)
            }
            runningIndex += count
        }
        return nil
    }
    
    /// Returns the global index of the first sentence in the next paragraph, if it exists.
    private func nextParagraphGlobalIndex(in chapter: ChapterContent, after globalIndex: Int) -> Int? {
        var runningIndex = 0
        for paragraph in chapter.paragraphs {
            let count = paragraph.sentences.count
            if globalIndex < runningIndex + count {
                let nextParagraphStart = runningIndex + count
                let total = chapter.paragraphs.reduce(0) { $0 + $1.sentences.count }
                return nextParagraphStart < total ? nextParagraphStart : nil
            }
            runningIndex += count
        }
        return nil
    }
    
    /// Returns the global index of the first sentence in the paragraph containing the given global index.
    private func paragraphStartIndex(for globalIndex: Int, in chapter: ChapterContent) -> Int? {
        var runningIndex = 0
        for paragraph in chapter.paragraphs {
            let count = paragraph.sentences.count
            if globalIndex < runningIndex + count {
                return runningIndex
            }
            runningIndex += count
        }
        return nil
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    // "Select Chapter" Button.
                    Button(action: { showingNavigationSheet = true }) {
                        HStack {
                            Spacer()
                            if selectedSubBook.subBookTitle.lowercased() == "default" {
                                Text(selectedChapter.chapterTitle)
                                    .font(.headline)
                            } else {
                                Text("\(selectedSubBook.subBookTitle) \(selectedChapter.chapterTitle)")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Enlarged Sentence Display Area.
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                        Text(currentSentence)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: geo.size.height * 0.65)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Playback Controls.
                    HStack {
                        Spacer()
                        Button(action: { skipBackwardAction() }) {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .font(.title)
                        }
                        .disabled(globalSentenceIndex == 0)
                        .foregroundColor(globalSentenceIndex == 0 ? .gray : .primary)
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
                        Button(action: { skipForwardAction() }) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .font(.title)
                        }
                        .disabled(isAtEnd)
                        .foregroundColor(isAtEnd ? .gray : .primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Normalized Slider for Chapter Navigation.
                    Slider(
                        value: Binding(
                            get: { sliderNormalized },
                            set: { newValue in
                                sliderNormalized = newValue
                                let computedIndex = Int(round(newValue * Double(totalSentences - 1)))
                                globalSentenceIndex = computedIndex
                                if let sentence = chapterContent.flatMap({ getCurrentSentence(from: $0, at: computedIndex) }) {
                                    currentSentence = sentence.text
                                    audioManager.loadAudio(for: sentence)
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
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            // Modal Sheet for Subbook/Chapter Selection.
            .sheet(isPresented: $showingNavigationSheet) {
                NavigationStack {
                    Form {
                        if book.subBooks.count > 1 && book.subBooks.first?.subBookTitle.lowercased() != "default" {
                            HStack {
                                Spacer()
                                Picker("", selection: $selectedSubBookIndex) {
                                    ForEach(0..<book.subBooks.count, id: \.self) { index in
                                        Text(book.subBooks[index].subBookTitle).tag(index)
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
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingNavigationSheet = false
                                updateCurrentSentenceForSelection()
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadBookState()
                updateGlobalAppStateForBookDetail()
                chapterContent = loadChapterContent(language: selectedLanguage1Code)
                if selectedChapterIndex >= selectedSubBook.chapters.count {
                    selectedChapterIndex = 0
                }
                globalSentenceIndex = bookState?.lastGlobalSentenceIndex ?? 0
                sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                if let content = chapterContent, let sentence = getCurrentSentence(from: content, at: globalSentenceIndex) {
                    currentSentence = sentence.text
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
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(availableLanguages: book.languages)
        }
        // onChange handlers for navigation state.
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
        .onChange(of: selectedLanguage1) {
            let languageCode = selectedLanguage1Code
            chapterContent = loadChapterContent(language: languageCode)
            if let content = chapterContent, let sentence = getCurrentSentence(from: content, at: globalSentenceIndex) {
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
    
    // MARK: - Helper: Get Sentence for Current Stage
    private func sentenceForCurrentStage() -> SentenceContent? {
        if currentPlaybackStage == 1 {
            return currentSentenceContent()
        } else if currentPlaybackStage == 2, let _ = selectedLanguage2Code {
            let content = loadChapterContent(language: selectedLanguage2Code!)
            return content.flatMap { getCurrentSentence(from: $0, at: globalSentenceIndex) }
        } else if currentPlaybackStage == 3, let _ = selectedLanguage3Code {
            let content = loadChapterContent(language: selectedLanguage3Code!)
            return content.flatMap { getCurrentSentence(from: $0, at: globalSentenceIndex) }
        }
        return nil
    }
    
    // MARK: - Helper: Get Current SentenceContent (primary language)
    private func currentSentenceContent() -> SentenceContent? {
        if let content = chapterContent {
            return getCurrentSentence(from: content, at: globalSentenceIndex)
        }
        return nil
    }
    
    // MARK: - Audio Completion Handler
    private func audioDidFinishPlaying() {
        guard isPlaying, let chapter = chapterContent else { return }
        
        if playbackMode == PlaybackMode.paragraph.rawValue {
            // In Paragraph mode:
            if let indices = paragraphIndices(for: globalSentenceIndex, in: chapter) {
                let currentParagraph = chapter.paragraphs[indices.paragraphIndex]
                if indices.localIndex < currentParagraph.sentences.count - 1 {
                    // Advance to the next sentence within the same paragraph.
                    globalSentenceIndex += 1
                    sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                    if let sentence = getCurrentSentence(from: chapter, at: globalSentenceIndex) {
                        currentSentence = sentence.text
                        audioManager.loadAudio(for: sentence)
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
                } else {
                    // End of paragraph reached.
                    if let startIndex = paragraphStartIndex(for: globalSentenceIndex, in: chapter) {
                        globalSentenceIndex = startIndex
                        sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                        print("DEBUG: Paragraph mode - End of paragraph reached; reset globalSentenceIndex to \(globalSentenceIndex)")
                    }
                    // Switch to the next language if available.
                    if currentPlaybackStage == 1, selectedLanguage2 != "None" {
                        if let content2 = loadChapterContent(language: selectedLanguage2),
                           let sentence = getCurrentSentence(from: content2, at: globalSentenceIndex) {
                            chapterContent = content2
                            currentSentence = sentence.text
                            currentPlaybackStage = 2
                            audioManager.loadAudio(for: sentence)
                            audioManager.setRate(Float(selectedSpeed2))
                            print("DEBUG: Paragraph mode - Switching to secondary language at globalSentenceIndex = \(globalSentenceIndex)")
                            audioManager.play()
                            return
                        }
                    } else if currentPlaybackStage == 2, selectedLanguage3 != "None" {
                        if let content3 = loadChapterContent(language: selectedLanguage3),
                           let sentence = getCurrentSentence(from: content3, at: globalSentenceIndex) {
                            chapterContent = content3
                            currentSentence = sentence.text
                            currentPlaybackStage = 3
                            audioManager.loadAudio(for: sentence)
                            audioManager.setRate(Float(selectedSpeed3))
                            print("DEBUG: Paragraph mode - Switching to tertiary language at globalSentenceIndex = \(globalSentenceIndex)")
                            audioManager.play()
                            return
                        }
                    } else {
                        // All languages have played for this paragraph.
                        chapterContent = loadChapterContent(language: selectedLanguage1Code)
                        if let nextParagraphStart = nextParagraphGlobalIndex(in: chapterContent!, after: globalSentenceIndex),
                           let sentence = getCurrentSentence(from: chapterContent!, at: nextParagraphStart) {
                            globalSentenceIndex = nextParagraphStart
                            sliderNormalized = totalSentences > 0 ? Double(globalSentenceIndex) / Double(totalSentences - 1) : 0.0
                            currentPlaybackStage = 1
                            currentSentence = sentence.text
                            audioManager.loadAudio(for: sentence)
                            audioManager.setRate(Float(selectedSpeed1))
                            print("DEBUG: Paragraph mode - Advancing to next paragraph: globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(totalSentences), sliderNormalized = \(sliderNormalized)")
                            audioManager.play()
                            return
                        } else {
                            // No next paragraph exists in the current chapter;
                            advanceToNextChapterOrSubBook()
                            return
                        }
                    }
                }
            }
        } else {
            // Sentence mode: existing behavior.
            if currentPlaybackStage == 1 {
                if let lang2 = selectedLanguage2Code,
                   let content2 = loadChapterContent(language: lang2),
                   let sentence2 = getCurrentSentence(from: content2, at: globalSentenceIndex) {
                    currentSentence = sentence2.text
                    audioManager.loadAudio(for: sentence2)
                    currentPlaybackStage = 2
                    audioManager.onPlaybackFinished = { self.audioDidFinishPlaying() }
                    audioManager.setRate(Float(selectedSpeed2))
                    print("DEBUG: Sentence mode - Switching to secondary language at globalSentenceIndex = \(globalSentenceIndex)")
                    audioManager.play()
                    return
                }
                if let lang3 = selectedLanguage3Code,
                   let content3 = loadChapterContent(language: lang3),
                   let sentence3 = getCurrentSentence(from: content3, at: globalSentenceIndex) {
                    currentSentence = sentence3.text
                    audioManager.loadAudio(for: sentence3)
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
                   let content3 = loadChapterContent(language: lang3),
                   let sentence3 = getCurrentSentence(from: content3, at: globalSentenceIndex) {
                    currentSentence = sentence3.text
                    audioManager.loadAudio(for: sentence3)
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
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = max(globalSentenceIndex - 5, 0)
        globalSentenceIndex = newIndex
        sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
        if let sentence = getCurrentSentence(from: content, at: globalSentenceIndex) {
            currentSentence = sentence.text
            audioManager.loadAudio(for: sentence)
            if isPlaying { audioManager.play() }
        }
        print("DEBUG: Skip Backward - globalSentenceIndex = \(globalSentenceIndex), totalSentences = \(total), sliderNormalized = \(sliderNormalized)")
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
    
    private func skipForwardAction() {
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        let newIndex = min(globalSentenceIndex + 5, total - 1)
        globalSentenceIndex = newIndex
        sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
        if let sentence = getCurrentSentence(from: content, at: globalSentenceIndex) {
            currentSentence = sentence.text
            audioManager.loadAudio(for: sentence)
            if isPlaying { audioManager.play() }
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
        guard let content = chapterContent else { return }
        let total = content.paragraphs.reduce(0) { $0 + $1.sentences.count }
        if globalSentenceIndex < total - 1 {
            globalSentenceIndex += 1
            sliderNormalized = total > 0 ? Double(globalSentenceIndex) / Double(total - 1) : 0.0
            if let sentence = getCurrentSentence(from: content, at: globalSentenceIndex) {
                currentSentence = sentence.text
                audioManager.loadAudio(for: sentence)
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
            } else if selectedSubBookIndex < book.subBooks.count - 1 {
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
        chapterContent = loadChapterContent(language: selectedLanguage1Code)
        globalSentenceIndex = 0
        sliderNormalized = 0.0
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
        } else if selectedSubBookIndex < book.subBooks.count - 1 {
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
            print("DEBUG: New chapter loaded. globalSentenceIndex reset to \(globalSentenceIndex)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.internalNavigation = false
        }
        saveBookState()
        updateGlobalAppStateForBookDetail()
    }
}

