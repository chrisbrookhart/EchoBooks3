import SwiftUI

struct BookDetailView: View {
    let book: Book
    
    // MARK: - Navigation & Persistence State
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
                    
                    // --- Chapter Picker (centered) ---
                    if selectedSubBook.chapters.count > 1 {
                        HStack {
                            Spacer()
                            Picker("Chapter", selection: $selectedChapterIndex) {
                                ForEach(0..<selectedSubBook.chapters.count, id: \.self) { index in
                                    // Use chapterTitle here instead of "Chapter X"
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
            .navigationTitle(book.bookTitle)
            .navigationBarTitleDisplayMode(.inline)
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
            // Left-justified language picker.
            Picker("", selection: $selectedLanguage) {
                ForEach(availableLanguages, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Right-justified speed picker.
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
