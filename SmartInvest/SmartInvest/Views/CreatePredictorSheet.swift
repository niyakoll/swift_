//
//  CreatePredictorSheet.swift
//  SmartInvest
//
//  Created by user on 26/12/2025.
//

import SwiftUI

/// A slide-up sheet for creating a new predictor model profile
struct CreatePredictorSheet: View {
    // MARK: - Input Fields (passed as bindings from parent)
    @Binding var modelName: String
    @Binding var description: String
    @Binding var apiURL: String
    @Binding var isAutoPredictEnabled: Bool
    
    // MARK: - Presentation Control
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Validation
    private var isFormValid: Bool {
        let trimmedName = modelName.trimmingCharacters(in: .whitespaces)
        let trimmedURL = apiURL.trimmingCharacters(in: .whitespaces)
        
        return !trimmedName.isEmpty &&
               !trimmedURL.isEmpty &&
               (trimmedURL.lowercased().hasPrefix("http://") || trimmedURL.lowercased().hasPrefix("https://"))
    }
    
    // MARK: - Create Action (callback to parent)
    var onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Model Information") {
                    TextField("Model Name *", text: $modelName)
                        .autocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description)
                        .autocapitalization(.sentences)
                }
                
                Section("API Configuration") {
                    TextField("API URL *", text: $apiURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Example: https://my-server.com/predict")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Section("Automation") {
                    Toggle("Auto-predict every day", isOn: $isAutoPredictEnabled)
                }
            }
            .navigationTitle("Create New Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()      // Tell parent to create the model
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview
#Preview {
    CreatePredictorSheet(
        modelName: .constant(""),
        description: .constant(""),
        apiURL: .constant(""),
        isAutoPredictEnabled: .constant(true),
        onCreate: { print("Create tapped") }
    )
}
