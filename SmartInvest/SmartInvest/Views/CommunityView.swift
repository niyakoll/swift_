//
//  CommunityView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct CommunityView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<6) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                            
                            VStack(alignment: .leading) {
                                Text("Investor123")
                                    .font(.headline)
                                Text("2 hours ago")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                        }
                        
                        Text("Gold looks bullish this week! Anyone else predicting above $2500?")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Community")
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    CommunityView()
}
