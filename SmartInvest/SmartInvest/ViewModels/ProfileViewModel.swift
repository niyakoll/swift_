//
//  ProfileViewModel.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation
import Supabase

@Observable
class ProfileViewModel {
    var profile: Profile?
    var isLoading = false
    var errorMessage: String?
    
    // Fetch current user's profile
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [Profile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: SupabaseManager.shared.client.auth.currentUser?.id ?? UUID())
                .execute()
                .value
            
            profile = response.first  // Should be only one row
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("❌ Fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // Save/update username
    func saveUsername(_ newUsername: String) async {
        guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let updatedProfile = Profile(id: userId, username: newUsername.trimmingCharacters(in: .whitespaces))
        
        do {
            // Upsert: Insert if new, update if exists
            try await SupabaseManager.shared.client
                .from("profiles")
                .upsert(updatedProfile, onConflict: "id")
                .execute()
            
            profile = updatedProfile  // Update local state
        } catch {
            errorMessage = "Failed to save username: \(error.localizedDescription)"
            print("❌ Save error: \(error)")
        }
        
        isLoading = false
    }
}
