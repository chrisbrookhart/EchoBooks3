//
//  AppState.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/8/25.
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

    init(lastOpenedView: LastOpenedView = .library, lastOpenedBookID: UUID? = nil) {
        self.lastOpenedView = lastOpenedView
        self.lastOpenedBookID = lastOpenedBookID
    }
}

