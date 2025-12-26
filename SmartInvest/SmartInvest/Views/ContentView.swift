//
//  ContentView.swift
//  SmartInvest
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isLoading = true
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundSecondary)
                
            } else if isAuthenticated {
                MainTabView()
                    .navigationBarBackButtonHidden(true)  // Extra safety
                
            } else {
                WelcomeView()
            }
        }
        .task {
            await checkAuthStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            isAuthenticated = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidAuthenticate)) { _ in
            isAuthenticated = true   // Fresh login → switch to MainTabView
        }
    }
    
    private func checkAuthStatus() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            isAuthenticated = true
            
            if let userEmail = session.user.email {
                UserDefaults.standard.set(userEmail, forKey: "userEmail")
                print("Auto-login successful for: \(userEmail)")
            }
            
        } catch {
            print("No valid session: \(error)")
            isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: "userEmail")
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}
