//
//  SupabaseManager.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
// SupabaseManager.swift
import Supabase
// instance for connecting with supabase(cloud database)
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..bzzgdwQNYiOIT92OSiFbUbGEsK9YpmqwX-usTRZ7Vps"
        )
    }
}
