//
//  WelcomeView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct WelcomeView: View {
    @State private var isLoggedIn = false
    
    // Staggered animation states
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var showFeatures = false
    @State private var chartOffset: CGFloat = 100
    
    @State private var coinRotation: Double = 0
    @State private var shineAngle: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    colors: [
                        Color.backgroundSecondary.opacity(0.8),
                        Color.primaryAccent.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // MARK: - Simple Floating Gold Particles (10 circles rising gently)
                ForEach(0..<10) { index in
                    Circle()
                        .fill(Color.primaryAccent.opacity(0.3))
                        .frame(width: 8 + CGFloat(index * 4), height: 8 + CGFloat(index * 4))
                        .offset(y: particleOffset(for: index))
                        .animation(
                            Animation.easeInOut(duration: 8 + Double(index))
                                .repeatForever(autoreverses: false),
                            value: particleOffset(for: index)
                        )
                }
                
                ScrollView {
                    VStack(spacing: 40) {
                        
                        // MARK: - Title & Tagline
                        VStack(spacing: 16) {
                            Text("Smart Invest")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 30)
                            
                            Text("AI-Powered Gold Price Prediction & Investor Community")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showTagline ? 1 : 0)
                                .offset(y: showTagline ? 0 : 30)
                        }
                        .padding(.top, 80)
                        
                        // MARK: - Flipping & Shining Gold Coin Hero
                        ZStack {
                            // Base coin (gold color)
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 160))
                                .foregroundStyle(Color.goldAccent)
                                .symbolEffect(.pulse, options: .repeating) // Gentle breathing shine
                            
                            // Shine overlay: Radial gradient that rotates slowly for realistic light reflection
                            AngularGradient(
                                colors: [.white.opacity(0.6), .clear, .white.opacity(0.3), .clear],
                                center: .center,
                                startAngle: .degrees(shineAngle),
                                endAngle: .degrees(shineAngle + 360)
                            )
                            .mask(
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 160))
                            )
                            .opacity(0.8)
                        }
                        .rotation3DEffect(
                            .degrees(coinRotation),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .shadow(color: Color.goldAccent.opacity(0.6), radius: 20, y: 10) // Glowing shadow
                        .onAppear {
                            // Flip animation (continuous)
                            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                                coinRotation += 360
                            }
                            
                            // Slow shine rotation (independent, subtle highlight sweep)
                            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                                shineAngle += 360
                            }
                        }
                        
                        // MARK: - Features
                        VStack(alignment: .leading, spacing: 24) {
                            FeatureRow(icon: "brain.head.profile", text: "AI predicts XAU/USD gold price using advanced RNN model")
                            FeatureRow(icon: "chart.bar.xaxis", text: "Track your prediction history and performance")
                            FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Join the community — share ideas and discuss gold market trends")
                            FeatureRow(icon: "hand.thumbsup.fill", text: "Simple, clear design made for beginner investors")
                        }
                        .padding(.horizontal, 32)
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 40)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // MARK: - Bottom Buttons
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 16) {
                        // MARK: - Animated Sign Up Button
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(.white)
                                .background(Color.primaryAccent)  // Blue, as you prefer
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.primaryAccent.opacity(0.6), radius: 12, y: 8)
                        }
                        .buttonStyle(PressAnimationStyle())  // Keep the press animation
                        .onTapGesture {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        
                        // MARK: - Animated Log In Button
                        NavigationLink(destination: SignInView()) {
                            Text("Log In")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(Color.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.textSecondary, lineWidth: 2.5)
                                )
                        }
                        .buttonStyle(PressAnimationStyle())  // ← Adds scale + opacity animation
                        .onTapGesture {
                            // Optional: Add light haptic feedback on tap
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                }
            }
            
            // MARK: - Staggered Entrance Animations
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showTitle = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    showTagline = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    showFeatures = true
                }
            }
            
            // MARK: - Navigation
            .navigationDestination(isPresented: $isLoggedIn) {
                MainTabView()
            }
        }
    }
    
    // Helper: Calculate rising offset for each particle
    private func particleOffset(for index: Int) -> CGFloat {
        let baseDelay = Double(index) * 1.5
        let time = Date().timeIntervalSinceReferenceDate + baseDelay
        let progress = (time.truncatingRemainder(dividingBy: 20)) / 20  // 20-second loop
        return CGFloat(progress * -900)  // Rise from bottom to top
    }
}

// MARK: - Feature Row (unchanged)
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.primaryAccent)
                .frame(width: 36, height: 36)
                .background(Color.primaryAccent.opacity(0.15))
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}
// MARK: - Custom Press Animation for Buttons
struct PressAnimationStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)     // Shrink slightly when pressed
            .opacity(configuration.isPressed ? 0.8 : 1.0)          // Fade slightly
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)  // Smooth & fast
    }
}
// MARK: - Previews
#Preview("Light Mode") {
    WelcomeView()
}

#Preview("Dark Mode") {
    WelcomeView()
        .preferredColorScheme(.dark)
}
