//
//  CommunityPost.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation
// Define a data structure of a community posit, use for community tab , allow user to share prediction
struct CommunityPost: Identifiable,Codable{
    let id: Int?
    let user_id: UUID
    let user_email: String
    let created_at: Date?
    let username: String?
    let model_name: String
    let model_description: String
    let prediction_date: String
    let predicted_price: Double
    let optimism_bias: Double
    let opinion: String
    // For SwiftUI List , formating date
    var displayDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: created_at ?? Date.now)
    }
    // for displaying prediction date
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
    // for checking if the prediction date is on the future
    var isFuturePrediction: Bool {
        // Parse prediction_date string "YYYY-MM-DD"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let predDate = formatter.date(from: prediction_date) else { return true }
        return predDate >= Date()  // Today or future
    }
    // for compareing the prediction price and the actual price
    var accuracyPercentage: Double? {
        guard let actual = actualPrice else { return nil }
        let diff = abs(predicted_price - actual)
        let accuracy = 100 - (diff / actual * 100)
        return max(0, min(100, accuracy))  // Clamp 0-100%
    }

    var actualPrice: Double? = nil  // actual dta will be fetched by external api
}
