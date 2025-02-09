
// BookDetailView.swift

import SwiftUI
import SwiftData

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext

    // MARK: - Navigation & Content State
    @State private var selectedSubBookIndex: Int = 0
    @State private var selectedChapterIndex: Int = 0

    // MARK: - Content Display & Playback State
    @State private var currentSentence: String = "This is a placeholder sentence for the currently playing audio."
    @State private var sliderValue: Double = 0.0
    @State private var isPlaying: Bool = false

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
    // For rows 2 and 3, include "None" as an option.
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

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- Subbook Picker (menu style, centered) ---
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
                    
                    // --- Chapter Picker (centered using chapterTitle) ---
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
                            // Skip backward action (placeholder)
                        }) {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .font(.title)
                        }
                        Spacer()
                        Button(action: {
                            isPlaying.toggle()
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                        }
                        Spacer()
                        Button(action: {
                            // Skip forward action (placeholder)
                        }) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .font(.title)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // --- Slider for Chapter Navigation ---
                    Slider(value: $sliderValue, in: 0...100)
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
            }
            .onDisappear {
                saveBookState()
                updateGlobalAppStateForBookDetail()
            }
        }
        .navigationTitle(book.bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Attach onChange handlers for immediate persistence.
        // Note that fixing deprecation warning merely requires deleting " _ in" (to make it a zero parameter function)
        .onChange(of: selectedSubBookIndex) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: selectedChapterIndex) {
            saveBookState()
            updateGlobalAppStateForBookDetail()
        }
        .onChange(of: sliderValue) {
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
