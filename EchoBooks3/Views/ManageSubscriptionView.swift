//
//  ManageSubscriptionView.swift
// 
//  A placeholder view for managing subscription accounts.
//

import SwiftUI

struct ManageSubscriptionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Manage Subscription")
                .font(.largeTitle)
                .padding(.top)
            Text("Subscription management functionality coming soon.")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Manage Subscription")
    }
}

struct ManageSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManageSubscriptionView()
        }
    }
}
