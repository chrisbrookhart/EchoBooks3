//
//  AppState.swift
//  EchoBooks3
// 
//
import Foundation
import SwiftData

enum LastOpenedView: String, CaseIterable, Codable {
    case library, bookDetail
}

@Model
final class AppState: Identifiable {
    var id: UUID = UUID()
    var lastOpenedView: LastOpenedView
    var lastOpenedBookID: UUID?  // Only set if the last opened view was BookDetailView
    var lastBookUnfinished: Bool = false  // True if the last book has unfinished playback

    init(lastOpenedView: LastOpenedView = .library, lastOpenedBookID: UUID? = nil, lastBookUnfinished: Bool = false) {
        self.lastOpenedView = lastOpenedView
        self.lastOpenedBookID = lastOpenedBookID
        self.lastBookUnfinished = lastBookUnfinished
    }
}

