//
//  ChapterJSONModels.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/10/25.
//

import Foundation

struct ChapterContent: Decodable {
    let chapterID: String
    let language: String
    let chapterNumber: Int
    let chapterTitle: String
    let paragraphs: [ParagraphContent]
}

struct ParagraphContent: Decodable {
    let paragraphID: String
    let paragraphIndex: Int
    let sentences: [SentenceContent]
}

struct SentenceContent: Decodable {
    let sentenceID: String
    let sentenceIndex: Int
    let globalSentenceIndex: Int
    let reference: String?
    let text: String
    let audioFile: String
}
