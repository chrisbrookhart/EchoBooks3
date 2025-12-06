//
//  BookState.swift
//  EchoBooks3
//
//

import Foundation
import SwiftData

@Model
final class BookState: Identifiable {
    var id: UUID = UUID()
    var bookID: UUID
    var lastGlobalSentenceIndex: Int
    var lastSubBookIndex: Int
    var lastChapterIndex: Int
    var lastSliderValue: Double

    init(bookID: UUID,
         lastGlobalSentenceIndex: Int = 0,
         lastSubBookIndex: Int = 0,
         lastChapterIndex: Int = 0,
         lastSliderValue: Double = 0.0) {
        self.bookID = bookID
        self.lastGlobalSentenceIndex = lastGlobalSentenceIndex
        self.lastSubBookIndex = lastSubBookIndex
        self.lastChapterIndex = lastChapterIndex
        self.lastSliderValue = lastSliderValue
    }
}


