//
//  SettingsView.swift
//  SmartInvest
//

import SwiftUI
import Supabase   // For real signOut()

struct SettingsView: View {
    // MARK: - State
    @State private var isLoggingOut = false          // Controls spinner & disable button
    @State private var showLogoutAlert = false       // Controls confirmation alert
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Account Section
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.primaryAccent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(UserDefaults.standard.string(forKey: "userEmail") ?? "Not available")
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Logout Section
                Section {
                    Button("Sign Out") {
                        showLogoutAlert = true   // Show confirmation first
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isLoggingOut)
                } footer: {
                    Text("You will be returned to the welcome screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Loading Overlay (optional but nice)
                if isLoggingOut {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Signing out...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            // Hide back button (already done in MainTabView)
            .navigationBarBackButtonHidden(true)
            
            // MARK: - Confirmation Alert
            .alert("Sign Out?", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await performSignOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out of your account?")
            }
        }
    }
    
    // MARK: - Real Supabase Sign Out
    private func performSignOut() async {
        isLoggingOut = true
        
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            
            // Clear saved email
            UserDefaults.standard.removeObject(forKey: "userEmail")
            
            print("✅ User signed out successfully")
            
            // Notify ContentView to switch back to Welcome
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
            
        } catch {
            print("❌ Sign out error: \(error)")
            // Even if there's an error, force local logout for safety
            UserDefaults.standard.removeObject(forKey: "userEmail")
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
        
        isLoggingOut = false
    }
}

#Preview {
    SettingsView()
}

#Preview("Dark Mode") {
    SettingsView()
        .preferredColorScheme(.dark)
}
