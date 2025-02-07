//
//  BookItemView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/6/25.
//


//
//  BookItemView.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
//  A view that displays a single book’s cover image and title.
//  It strips any file extension from the cover image name and falls back to "DefaultCover" if necessary.
//

import SwiftUI

struct BookItemView: View {
    let book: Book
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            coverImage(for: book)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(8)
            Text(book.bookTitle)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
    }
    
    /// Helper to retrieve the cover image by stripping file extension.
    private func coverImage(for book: Book) -> Image {
        let assetName = (book.coverImageName as NSString).deletingPathExtension
        if UIImage(named: assetName) != nil {
            return Image(assetName)
        } else {
            return Image("DefaultCover")
        }
    }
}

struct BookItemView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
