//
//  SupabaseManager.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
// SupabaseManager.swift
import Supabase   // ← This should now work with NO error

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://.supabase.co")!,  // ← Replace with your real URL
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..bzzgdwQNYiOIT92OSiFbUbGEsK9YpmqwX-usTRZ7Vps"                                 // ← Replace with your anon key
        )
    }
}
