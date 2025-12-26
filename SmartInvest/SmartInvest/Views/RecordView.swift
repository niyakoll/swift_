//
//  RecordView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct RecordView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<8) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gold Price Prediction")
                                .font(.headline)
                            Text("Dec 20, 2025 • 1-week horizon")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Text("$2,450")
                            .font(.title3.bold())
                            .foregroundStyle(Color.successAccent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Record")
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    RecordView()
}
