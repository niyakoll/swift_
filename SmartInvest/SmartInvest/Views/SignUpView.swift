//
//  SignUpView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct SignUpView: View {
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Control navigation after successful signup (mock)
    @State private var isSignedUp = false
    
    // Alert control
    @State private var showSuccessAlert = false
    
    // For dismissing back to Welcome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode  // Legacy but reliable for pop-to-root
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // MARK: - Title
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
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderSeparator, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                
                // MARK: - Sign Up Button
                Button("Sign Up") {
                    // Mock success: trigger alert
                    showSuccessAlert = true
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    // Disable if fields empty or passwords don't match
                    email.isEmpty || password.isEmpty || password != confirmPassword
                        ? Color.gray.opacity(0.4)
                        : Color.primaryAccent  // Your preferred blue accent
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .disabled(email.isEmpty || password.isEmpty || password != confirmPassword)
                
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                                // Pop to root – go directly to WelcomeView
                                // This works because WelcomeView is the root of the NavigationStack
                                dismiss()
                                dismiss()  // Call twice – safe for deep navigation (Sign In → Sign Up)
                                // SwiftUI stops when it reaches root, no crash
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                    
                                }
                                .foregroundStyle(Color.primaryAccent)
                            }
                }
            }
            
            // MARK: - Success Alert
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    isSignedUp = true  // Navigate to main app after dismissing alert
                }
            } message: {
                Text("Your account has been created successfully!")
            }
            
            // MARK: - Navigation to Main App
            .navigationDestination(isPresented: $isSignedUp) {
                MainTabView()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SignUpView()
}

#Preview("Dark Mode") {
    SignUpView()
        .preferredColorScheme(.dark)
}
