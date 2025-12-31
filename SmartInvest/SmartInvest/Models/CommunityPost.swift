//
//  CommunityPost.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation

struct CommunityPost: Identifiable,Codable{
    let id: Int?
    let user_id: UUID
    let user_email: String
    let created_at: Date?
    let username: String?
    let model_name: String
    let model_description: String
    let prediction_date: String  // ← String for date column
    let predicted_price: Double
    let optimism_bias: Double
    let opinion: String
    // For SwiftUI List
        var displayDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: created_at ?? Date.now)
        }
    var predictionDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        // Since prediction_date is stored as "YYYY-MM-DD" string
        if let date = ISO8601DateFormatter().date(from: prediction_date + "T00:00:00Z") {
            return formatter.string(from: date)
        }
        return prediction_date  // fallback
    }
    // Add these inside CommunityPost struct
    var isFuturePrediction: Bool {
        // Parse prediction_date string "YYYY-MM-DD"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let predDate = formatter.date(from: prediction_date) else { return true }
        return predDate >= Date()  // Today or future
    }

    var accuracyPercentage: Double? {
        guard let actual = actualPrice else { return nil }
        let diff = abs(predicted_price - actual)
        let accuracy = 100 - (diff / actual * 100)
        return max(0, min(100, accuracy))  // Clamp 0-100%
    }

    var actualPrice: Double? = nil  // We'll set this from fetched data
}
