//
//  SharePredictionSheet.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import Foundation
import SwiftUI
import Supabase

/// Slide-up sheet for sharing a prediction to the community
struct SharePredictionSheet: View {
    // MARK: - Prediction Data (passed from detail view)
    let modelName: String
    let modelDescription: String
    let predictionDate: Date
    let predictedPrice: Double
    let optimismBias: Double
    @State private var isUploading = false
    @State private var showSuccessMessage = false
    
    // MARK: - User Opinion
    @State private var opinionText = ""
    private let maxWords = 150
    
    // MARK: - Confirmation
    @State private var showingConfirmAlert = false
    
    // MARK: - Dismiss
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Computed
    private var wordCount: Int {
        opinionText.split(separator: " ").count
    }
    
    private var remainingWords: Int {
        maxWords - wordCount
    }
    
    private var isValid: Bool {
        !opinionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        wordCount <= maxWords
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Prediction Summary (Read-only)
                Section("Your Prediction") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Model")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(modelName)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Date")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(predictionDate, format: .dateTime.month(.abbreviated).day().year())
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Predicted Price")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("$\(predictedPrice.formatted(.number.precision(.fractionLength(2))))")
                                .font(.title3.bold())
                                .foregroundStyle(Color.goldAccent)
                        }
                        
                        HStack {
                            Text("Personal Bias")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(optimismBias, specifier: "%.0f")%")
                                .fontWeight(.semibold)
                                .foregroundStyle(optimismBias > 0 ? Color.successAccent : optimismBias < 0 ? .red : .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Model Description
                if !modelDescription.isEmpty {
                    Section("Model Description") {
                        Text(modelDescription)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                // MARK: - Opinion Input
                Section("Your Opinion") {
                    TextEditor(text: $opinionText)
                        .frame(minHeight: 120)
                    
                    HStack {
                        Text("\(remainingWords) words remaining")
                            .font(.caption)
                            .foregroundStyle(remainingWords < 20 ? .red : Color.textSecondary)
                        
                        Spacer()
                        
                        Text("\(wordCount)/\(maxWords)")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                // MARK: - Security Note
                Section {
                    Label(
                        title: { Text("Do not share your API URL — it may contain private keys.") },
                        icon: { Image(systemName: "exclamationmark.shield.fill") }
                    )
                    .foregroundStyle(.orange)
                    .font(.caption)
                }
            }
            .navigationTitle("Share Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        showingConfirmAlert = true
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert("Share to Community?", isPresented: $showingConfirmAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Share", role: .none) {
                    isUploading = true  // Start loading
                    Task {
                        await uploadPostToSupabase()
                        await MainActor.run {
                            isUploading = false
                            showSuccessMessage = true
                        }
                    }
                    dismiss()
                }
            } message: {
                Text("Your prediction and opinion will be visible to all users.")
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Sharing to community...")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(30)
                        .background(Color.primaryAccent.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 20)
                    }
                }
            }
            .alert("Posted Successfully! 🎉", isPresented: $showSuccessMessage) {
                Button("OK") {}
            } message: {
                Text("Your prediction is now visible to the community.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        
    }
    private func uploadPostToSupabase() async {
        print("1. Starting upload...")
        
        do {
            print("2. Getting auth session...")
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            print("3. Got user: \(user.id) – email: \(user.email ?? "nil")")
            
            // Fetch username
            print("4. Fetching username from profiles...")
            let profiles: [Profile]
            do {
                profiles = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("id, username")
                    .eq("id", value: user.id)
                    .execute()
                    .value
                print("5. Fetched profiles count: \(profiles.count)")
            } catch {
                print("5. Failed to fetch profiles: \(error)")
                profiles = []
            }
            
            let username = profiles.first?.username ?? "Anonymous"
            let email = user.email ?? "unknown@example.com"
            
            // Date string
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: predictionDate)
            print("6. Date string: \(dateString)")
            
            // Opinion
            let cleanOpinion = opinionText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanOpinion.isEmpty else {
                print("7. Opinion is empty – aborting upload")
                return
            }
            print("7. Opinion length: \(cleanOpinion.count)")
            
            // Create post
            print("8. Creating CommunityPost...")
            let post = CommunityPost(
                user_id: user.id,
                user_email: email,
                username: username,
                model_name: modelName,
                model_description: modelDescription,
                prediction_date: dateString,
                predicted_price: predictedPrice,
                optimism_bias: optimismBias,
                opinion: cleanOpinion
            )
            
            print("9. Payload created: \(post)")
            
            // Insert
            print("10. Sending to Supabase...")
            try await SupabaseManager.shared.client
                .from("community_posts")
                .insert(post)
                .execute()
            
            print("✅ Post uploaded successfully!")
            
        } catch {
            print("❌ Upload failed early: \(error.localizedDescription)")
            if let pgError = error as? PostgrestError {
                print("PostgREST details: \(pgError)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SharePredictionSheet(
        modelName: "My Gold Pro",
        modelDescription: "Custom RNN with volatility adjustment",
        predictionDate: Date().addingTimeInterval(86400),
        predictedPrice: 4512.34,
        optimismBias: 15
    )
}
