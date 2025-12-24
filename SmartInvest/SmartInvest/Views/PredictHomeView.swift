//
//  PredictHomeView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct PredictHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Predict")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.primaryAccent)
                
                Text("Choose an AI predictor below")
                    .font(.title3)
                    .foregroundStyle(Color.textSecondary)
                
                // Placeholder predictor cards
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundSecondary)
                        .frame(height: 120)
                        .overlay(
                            Text("Predictor Card Placeholder")
                                .foregroundStyle(Color.textSecondary)
                        )
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Predict")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PredictHomeView()
}

#Preview("Dark Mode") {
    PredictHomeView()
        .preferredColorScheme(.dark)
}
