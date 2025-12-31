//
//  SignInView.swift
//  SmartInvest
//
//  Updated for real Supabase authentication
//

import SwiftUI
import Supabase                  // ← Access to Supabase client
import Foundation
struct SignInView: View {
    // MARK: - Form Fields
    @State private var email = ""
    @State private var password = ""
    
    // MARK: - UI State
    @State private var isLoading = false          // Shows spinner
    @State private var errorMessage: String?      // Shows red error text
    @State private var isLoggedIn = false         // Triggers navigation
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss   // Back to WelcomeView
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Sign in to your SmartInvest account")
                        .font(.title3)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                
                // MARK: - Input Fields
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )
                    
                    SecureField("Password", text: $password)
                        .textContentType(.oneTimeCode)   // ← Suppresses strong password overlay
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                
                // MARK: - Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal, 32)
                }
                
                // MARK: - Sign In Button
                Button("Sign In") {
                    Task {
                        await performSignIn()
                    }
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(signInButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .disabled(isLoading || !isFormValid)
                
                // MARK: - Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .padding()
                }
                
                // MARK: - Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(Color.textSecondary)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primaryAccent)
                    }
                }
                .font(.subheadline)
                
                Spacer()
            }
            // MARK: - Toolbar (custom back button)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            
            // MARK: - Navigation to Main App after login
            .onChange(of: isLoggedIn) {
                if isLoggedIn {
                    let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    UserDefaults.standard.set(cleanEmail, forKey: "userEmail")
                    
                    NotificationCenter.default.post(name: .userDidAuthenticate, object: nil)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Form is valid when both fields are filled
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
    
    /// Button color: gold when ready, gray when disabled
    private var signInButtonColor: Color {
        isFormValid && !isLoading ? Color.primaryAccent : Color.gray.opacity(0.4)
    }
    
    // MARK: - Real Supabase Sign In Logic
    private func performSignIn() async {
        isLoading = true
        errorMessage = nil
        
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            // Real Supabase sign in call
            try await SupabaseManager.shared.client.auth.signIn(
                email: cleanEmail,
                password: password
            )
            
            // Success! Save email locally so Settings can show it
            UserDefaults.standard.set(cleanEmail, forKey: "userEmail")
            
            print("✅ Sign in successful for: \(cleanEmail)")
            
            // Navigate to main tab view
            isLoggedIn = true
            
        } catch let authError as AuthError {
            errorMessage = authError.localizedDescription
            print("❌ Supabase Auth Error: \(authError.localizedDescription)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Unexpected error: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    SignInView()
}
