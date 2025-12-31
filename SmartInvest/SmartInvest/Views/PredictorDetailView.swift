import SwiftUI
import Supabase
struct PredictorDetailView: View {
    // MARK: - Model & Callbacks
    let model: PredictorModel
    var onDelete: () -> Void
    var onEdit: (PredictorModel) -> Void
    
    // MARK: - Editable Copies
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var editedApiURL: String
    @State private var isAutoPredictEnabled: Bool
    
    // MARK: - Prediction Settings
    @State private var selectedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var optimismBias: Double = 0
    
    // MARK: - Mock Prediction
    @State private var predictedPrice: Double = 4512.34
    // MARK: - Save Prediction
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    // MARK: - Share Prediction
    @State private var showingShareSheet = false
    
    // MARK: - Animation
    @State private var isPredicting = false
    @State private var shineAngle: Double = 0
    @State private var particleScales: [CGFloat] = Array(repeating: 0, count: 8)
    
    // MARK: - Delete Alert
    @State private var showingDeleteAlert = false
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Helper
    private var isDefaultModel: Bool {
        model.name == "SmartInvest Default"
    }
    
    // MARK: - Init
    init(
        model: PredictorModel,
        onDelete: @escaping () -> Void = {},
        onEdit: @escaping (PredictorModel) -> Void = { _ in }
    ) {
        self.model = model
        self.onDelete = onDelete
        self.onEdit = onEdit
        
        _editedName = State(initialValue: model.name)
        _editedDescription = State(initialValue: model.description)
        _editedApiURL = State(initialValue: model.apiURL)
        _isAutoPredictEnabled = State(initialValue: model.isAutoPredictEnabled)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Model Details
                Section("Model Details") {
                    TextField("Model Name", text: $editedName)
                        .autocapitalization(.words)
                        .disabled(isDefaultModel)
                    
                    TextField("Description", text: $editedDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .disabled(isDefaultModel)
                    
                    TextField("API URL", text: $editedApiURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(isDefaultModel)
                }
                
                // MARK: Auto Predict Toggle
                Section {
                    Toggle("Auto-predict every day", isOn: $isAutoPredictEnabled)
                        .disabled(isDefaultModel)
                }
                
                // MARK: Customize Prediction
                Section("Customize Prediction") {
                    DatePicker(
                        "Prediction Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Market Optimism")
                            .font(.headline)
                        
                        HStack {
                            Text("Pessimistic").font(.caption).foregroundStyle(.red)
                            Spacer()
                            Text("Neutral").font(.caption)
                            Spacer()
                            Text("Optimistic").font(.caption).foregroundStyle(Color.successAccent)
                        }
                        
                        Slider(value: $optimismBias, in: -100...100, step: 1)
                            .tint(Color.primaryAccent)
                        
                        Text("Bias: \(optimismBias, specifier: "%.0f")%")
                            .font(.title3.bold())
                            .foregroundStyle(optimismBias > 0 ? Color.successAccent : optimismBias < 0 ? .red : .primary)
                    }
                }
                
                // MARK: Predicted Price (split to avoid type-checker bug)
                Section("Predicted Price") {
                    ZStack {
                        PriceCardBackground()
                        PriceContent()
                        ShineOverlay()
                        SparklesOverlay()
                    }
                    .animation(.easeInOut(duration: 0.6), value: isPredicting)
                }
                
                // MARK: Action Buttons
                Section {
                    Button("Predict Now") {
                        triggerPredictAnimation()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.primaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    
                    HStack(spacing: 16) {
                        Button("Save") {
                            isSaving = true
                            Task {
                                await savePredictionToSupabase()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(isSaving ? Color.gray : Color.successAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(isSaving)

                        // Optional: success alert
                        .alert("Saved Successfully!", isPresented: $showSaveSuccess) {
                            Button("OK") {}
                        } message: {
                            Text("Your prediction has been saved to your records.")
                        }
                        
                        Button("Share") {
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        // ← Add this sheet modifier (place it after the button, inside the Section)
                        .sheet(isPresented: $showingShareSheet) {
                            SharePredictionSheet(
                                modelName: model.name,
                                modelDescription: model.description,
                                predictionDate: selectedDate,
                                predictedPrice: predictedPrice,
                                optimismBias: optimismBias
                            )
                        }
                        
                    }
                    
                    Button("Delete Model", role: .destructive) {
                        if !isDefaultModel {
                            showingDeleteAlert = true
                        }
                    }
                    .disabled(isDefaultModel)
                    .alert("Delete All Records?", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            Task {
                                await deleteModelRecords()
                            }
                        }
                    } message: {
                        Text("This will permanently delete ALL predictions for '\(model.name)'. This cannot be undone.")
                    }
                }
                
            }
            .navigationTitle(editedName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if !isDefaultModel {
                            let updated = PredictorModel(
                                name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: editedDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                                apiURL: editedApiURL.trimmingCharacters(in: .whitespacesAndNewlines),
                                isAutoPredictEnabled: isAutoPredictEnabled
                            )
                            onEdit(updated)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Model?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete '\(model.name)' and all its records. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Sub-views (fixes type-checker overload)
    @ViewBuilder private func PriceCardBackground() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.backgroundSecondary)
            .shadow(
                color: isPredicting ? Color.goldAccent.opacity(0.8) : Color.black.opacity(0.1),
                radius: isPredicting ? 20 : 8,
                y: isPredicting ? 12 : 4
            )
    }
    
    @ViewBuilder private func PriceContent() -> some View {
        VStack(spacing: 12) {
            Text("Predicted Price for \(selectedDate, format: .dateTime.month(.abbreviated).day().year())")
                .font(.title3)
                .foregroundStyle(.primary)
            
            Text("$\(predictedPrice.formatted(.number.precision(.fractionLength(2))))")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(Color.goldAccent)
                .scaleEffect(isPredicting ? 1.15 : 1.0)
                .opacity(isPredicting ? 0.8 : 1.0)
            
            Text("AI Base + \(optimismBias, specifier: "%.0f")% personal bias")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding()
    }
    
    @ViewBuilder private func ShineOverlay() -> some View {
        if isPredicting {
            AngularGradient(
                colors: [.clear, Color.goldAccent.opacity(0.6), .clear],
                center: .center,
                startAngle: .degrees(shineAngle),
                endAngle: .degrees(shineAngle + 180)
            )
            .mask(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    @ViewBuilder private func SparklesOverlay() -> some View {
        if isPredicting {
            ForEach(0..<8) { i in
                Circle()
                    .fill(Color.goldAccent)
                    .frame(width: 6, height: 6)
                    .offset(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: -40...40))
                    .opacity(Double.random(in: 0.4...1))
                    .scaleEffect(particleScales[i])
                    .animation(
                        .easeOut(duration: 0.6)
                            .delay(Double(i) * 0.05)
                            .repeatCount(1),
                        value: particleScales[i]
                    )
            }
        }
    }
    private func savePredictionToSupabase() async {
        isSaving = true
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            
            let email = user.email ?? "unknown@example.com"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: selectedDate)
            
            //let cleanOpinion = opinionText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let record = PredictionRecord(
                id: nil,
                created_at: nil,
                user_id: user.id,
                user_email: email,
                model_id: model.id,
                model_name: model.name,
                prediction_date: dateString,
                predicted_price: predictedPrice,
                optimism_bias: optimismBias
            )
            
            // ← UPSERT: update if same user + date exists
            try await SupabaseManager.shared.client
                .from("prediction_records")
                .upsert(record, onConflict: "user_id,prediction_date,model_id")
                .execute()
            
            await MainActor.run {
                isSaving = false
                showSaveSuccess = true
            }
            
        } catch {
            await MainActor.run {
                isSaving = false
            }
            print("Save failed: \(error)")
        }
    }
    // MARK: - Delete Model Record
    private func deleteModelRecords() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            
            try await SupabaseManager.shared.client
                .from("prediction_records")
                .delete()
                .eq("user_id", value: user.id)
                .eq("model_id", value: model.id)
                .execute()
            
            print("All records for model \(model.name) deleted")
            
            await MainActor.run {
                onDelete()  // Tell parent to remove model from list
                dismiss()
            }
            
        } catch {
            print("Delete failed: \(error)")
            // Optional: show error alert
        }
    }
    // MARK: - Predict Animation
    private func triggerPredictAnimation() {
        isPredicting = true
        shineAngle = 0
        particleScales = Array(repeating: 0, count: 8)
        
        withAnimation(.easeInOut(duration: 0.8)) {
            shineAngle = 360
            particleScales = Array(repeating: 1, count: 8)
        }
        
        // Mock price
        let base = 4500.0
        let randomChange = Double.random(in: -30...30)
        predictedPrice = base + randomChange + (optimismBias / 100 * 100)
        
        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { isPredicting = false }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PredictorDetailView(
            model: .previewUser,
            onDelete: { print("Deleted") },
            onEdit: { _ in print("Edited") }
        )
    }
}
