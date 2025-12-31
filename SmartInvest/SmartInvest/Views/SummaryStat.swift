//
//  SummaryStat.swift
//  SmartInvest
//
//  Created by user on 29/12/2025.
//

import Foundation
import SwiftUI

/// Reusable stat row for summary cards
struct SummaryStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    SummaryStat(label: "Total Predictions", value: "42")
        .padding()
        .background(Color.backgroundSecondary)
}
