//
//  CommunityPost.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation

struct CommunityPost: Codable {
    let user_id: UUID
    let user_email: String
    let username: String?
    let model_name: String
    let model_description: String
    let prediction_date: String  // ← String for date column
    let predicted_price: Double
    let optimism_bias: Double
    let opinion: String
}
