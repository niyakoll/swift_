//
//  SignUpView.swift
//  SmartInvest
//
//  Updated for real Supabase authentication
//
import Foundation
import SwiftUI
import Supabase                  // ← Important: access to Supabase client

struct SignUpView: View {
    // MARK: - Form Fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // MARK: - UI State
    @State private var isLoading = false          // Shows spinner on button
    @State private var errorMessage: String?      // Shows red text if something fails
    @State private var isSignedUp = false         // Triggers navigation to MainTabView
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss   // To go back to WelcomeView
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Join SmartInvest and start predicting gold prices")
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
                        .textContentType(.oneTimeCode)   // ← Add this line
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.oneTimeCode)   // ← Add this line too
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
                
                // MARK: - Sign Up Button
                Button("Sign Up") {
                    Task {
                        await performSignUp()
                    }
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(signUpButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .disabled(isLoading || !isFormValid)          // Disable if invalid
                
                // MARK: - Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .padding()
                }
                
                // MARK: - Log In Link
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(Color.textSecondary)
                    
                    NavigationLink(destination: SignInView()) {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primaryAccent)
                    }
                }
                .font(.subheadline)
                
                Spacer()
            }
            // MARK: - Toolbar (back button)
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
            
            // MARK: - Navigation after successful signup
            .onChange(of: isSignedUp) {
                if isSignedUp {   // We can still read the state directly
                    let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    UserDefaults.standard.set(cleanEmail, forKey: "userEmail")
                    
                    NotificationCenter.default.post(name: .userDidAuthenticate, object: nil)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Determines if form is valid: all fields filled + passwords match
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }
    
    /// Button background color – gray when disabled, gold when ready
    private var signUpButtonColor: Color {
        isFormValid && !isLoading ? Color.primaryAccent : Color.gray.opacity(0.4)
    }
    
    // MARK: - Real Supabase Sign Up Logic
    private func performSignUp() async {
        // Reset UI state
        isLoading = true
        errorMessage = nil
        
        // Clean email (remove extra spaces)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            // Real Supabase sign up call
            let authResponse = try await SupabaseManager.shared.client.auth.signUp(
                email: cleanEmail,
                password: password
            )
            
            // Success! Save the user's email locally (for displaying in Settings later)
            UserDefaults.standard.set(cleanEmail, forKey: "userEmail")
            
            print("✅ Sign up successful for: \(cleanEmail)")
            print("User ID: \(authResponse.user.id)")  // You can see this in console
            
            // Navigate to the main app
            isSignedUp = true
            
        } catch let authError as AuthError {
            // This catches specific Supabase auth errors with nice messages
            errorMessage = authError.localizedDescription
            
            print("❌ Supabase Auth Error: \(authError.localizedDescription)")
            
        } catch {
            // This catches any other unexpected errors (e.g., network issues)
            errorMessage = error.localizedDescription
            
            print("❌ Unexpected error: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    SignUpView()
}
