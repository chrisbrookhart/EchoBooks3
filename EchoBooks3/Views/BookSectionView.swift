//
//  BookSectionView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/6/25.
//


//
//  BookSectionView.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
//  A view that displays a section header and a horizontal scroll view of BookItemViews.
//

import SwiftUI

struct BookSectionView: View {
    let title: String
    let books: [Book]
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            if books.isEmpty {
                // Empty state view for this section.
                VStack(spacing: 8) {
                    Text("No books found.")
                    Text("Please check back later.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(books, id: \.id) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                BookItemView(book: book, width: itemWidth, height: itemHeight)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: books.count)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct BookSectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Use dummy data for preview.
        EmptyView()
    }
}
