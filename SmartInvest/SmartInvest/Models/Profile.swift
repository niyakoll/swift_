//
//  Profile.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var username: String?
    var email: String?
    
    // For Codable when updating (only send what we change)
    enum CodingKeys: String, CodingKey {
        case id, username, email
    }
}
