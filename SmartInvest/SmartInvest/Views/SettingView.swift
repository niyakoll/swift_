//
//  SettingsView.swift
//  SmartInvest
//
//  Complete Settings page with username edit, email display, and logout.
//

import SwiftUI
import Supabase  // For auth.signOut()

struct SettingsView: View {
    // MARK: - ViewModel
    @State private var viewModel = ProfileViewModel()
    
    // MARK: - UI State
    @State private var usernameInput = ""
    @State private var isEditingUsername = false
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Section
                Section("Profile") {
                    // Email Row
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.title2)
                            .foregroundStyle(Color("PrimaryAccent"))
                            .frame(width: 36, height: 36)
                            .background(Color("PrimaryAccent").opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                            
                            Text(viewModel.profile?.email ?? "Loading...")
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // Username Row
                    if let currentUsername = viewModel.profile?.username, !currentUsername.isEmpty {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundStyle(Color("PrimaryAccent"))
                                .frame(width: 36, height: 36)
                                .background(Color("PrimaryAccent").opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Username")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("TextSecondary"))
                                
                                Text(currentUsername)
                                    .font(.body)
                                    .foregroundStyle(Color("PrimaryAccent"))
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                usernameInput = currentUsername
                                isEditingUsername = true
                            }
                            .foregroundStyle(Color("PrimaryAccent"))
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button("Set Username") {
                            usernameInput = ""
                            isEditingUsername = true
                        }
                        .foregroundStyle(Color("PrimaryAccent"))
                    }
                }
                .listRowBackground(Color("BackgroundSecondary"))
                
                // MARK: - Logout Section
                Section {
                    Button("Sign Out") {
                        showLogoutAlert = true
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DestructiveAccent"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isLoggingOut)
                } footer: {
                    Text("You will be returned to the welcome screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))  // Clean background
            
            // MARK: - Load Profile on Appear
            .task {
                await viewModel.fetchProfile()
            }
            
            // MARK: - Username Edit Sheet
            .sheet(isPresented: $isEditingUsername) {
                NavigationStack {
                    Form {
                        Section("Edit Username") {
                            TextField("Username", text: $usernameInput)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button("Save") {
                            Task {
                                await viewModel.saveUsername(usernameInput)
                                isEditingUsername = false
                            }
                        }
                        .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                    }
                    .navigationTitle("Edit Username")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isEditingUsername = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            
            // MARK: - Loading Overlay
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .scaleEffect(1.2)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // MARK: - Error Alert
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            
            // MARK: - Logout Confirmation Alert
            .alert("Sign Out?", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await performSignOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Sign Out Logic
    private func performSignOut() async {
        isLoggingOut = true
        
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            
            // Clear local data
            UserDefaults.standard.removeObject(forKey: "userEmail")
            
            print("✅ Signed out successfully")
            
            // Notify app to switch to WelcomeView (using your existing notification)
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
            
        } catch {
            print("❌ Sign out error: \(error)")
            // Force local logout anyway
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
        
        isLoggingOut = false
    }
}

#Preview("Light Mode") {
    SettingsView()
}

#Preview("Dark Mode") {
    SettingsView()
        .preferredColorScheme(.dark)
}
