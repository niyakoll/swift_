//
//  SignInView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct SignInView: View {
    // Mock states for email and password (fake login)
    @State private var email = ""
    @State private var password = ""
    
    // Control navigation after "login"
    @State private var isLoggedIn = false
    
    // For dismissing this view (back to Welcome)
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // MARK: - Title
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
                    // Email Field
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
                    
                    // Password Field (secure)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                
                // MARK: - Log In Button
                Button("Sign In") {
                    // Mock login: just navigate to main app
                    isLoggedIn = true
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    // Disable button if fields empty (good UX)
                    email.isEmpty || password.isEmpty
                        ? Color.gray.opacity(0.4)
                        : Color.primaryAccent  // Using your new gold color!
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .disabled(email.isEmpty || password.isEmpty)
                
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
            .navigationBarBackButtonHidden(true)  // Clean look
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
            .navigationDestination(isPresented: $isLoggedIn) {
                MainTabView()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SignInView()
}

#Preview("Dark Mode") {
    SignInView()
        .preferredColorScheme(.dark)
}
