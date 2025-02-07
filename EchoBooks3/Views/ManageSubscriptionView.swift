//
//  ManageSubscriptionView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/6/25.
//


//
//  ManageSubscriptionView.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
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
