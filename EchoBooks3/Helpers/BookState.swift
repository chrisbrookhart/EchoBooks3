//
//  BookState.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/8/25.
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




////
////  BookState.swift
////  EchoBooks3
////
////  Created by Chris Brookhart on 2/8/25.
////
//
//import Foundation
//import SwiftData
//
//@Model
//final class BookState: Identifiable {
//    var id: UUID = UUID()
//    var bookID: UUID
//    var lastGlobalSentenceIndex: Int
//    var lastSubBookIndex: Int
//    var lastChapterIndex: Int
//    var lastSliderValue: Double
//    
//    var selectedLanguage1: String
//    var selectedLanguage2: String
//    var selectedLanguage3: String
//    
//    var selectedSpeed1: Double
//    var selectedSpeed2: Double
//    var selectedSpeed3: Double
//
//    init(bookID: UUID,
//         lastGlobalSentenceIndex: Int = 0,
//         lastSubBookIndex: Int = 0,
//         lastChapterIndex: Int = 0,
//         lastSliderValue: Double = 0.0,
//         selectedLanguage1: String = "English",
//         selectedLanguage2: String = "None",
//         selectedLanguage3: String = "None",
//         selectedSpeed1: Double = 1.0,
//         selectedSpeed2: Double = 1.0,
//         selectedSpeed3: Double = 1.0) {
//        self.bookID = bookID
//        self.lastGlobalSentenceIndex = lastGlobalSentenceIndex
//        self.lastSubBookIndex = lastSubBookIndex
//        self.lastChapterIndex = lastChapterIndex
//        self.lastSliderValue = lastSliderValue
//        self.selectedLanguage1 = selectedLanguage1
//        self.selectedLanguage2 = selectedLanguage2
//        self.selectedLanguage3 = selectedLanguage3
//        self.selectedSpeed1 = selectedSpeed1
//        self.selectedSpeed2 = selectedSpeed2
//        self.selectedSpeed3 = selectedSpeed3
//    }
//}
//
