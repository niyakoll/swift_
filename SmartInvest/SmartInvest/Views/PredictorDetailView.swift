import SwiftUI
import Supabase
//when user click the ai model card, they will go to the ai model detail page, this page allow user to predit gold price with ai mode, or manual input their prediction
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
    // MARK: - Real API Prediction
    @State private var predictedPrice: Double? = nil  // Optional until predicted
    @State private var isLoadingPrediction = false
    @State private var predictionError: String?
    @State private var showingErrorAlert = false  // Controls the alert
    @State private var alertMessage = ""         // Custom message text
    // MARK: - Prediction Settings
    @State private var selectedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var optimismBias: Double = 0
    // MARK: - Manual Edit
    @State private var showingEditSheet = false  // Controls the edit sheet
    // MARK: - Mock Prediction
    //@State private var predictedPrice: Double = 4512.34 // mock data before connect with real ai model
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
    private var minSelectableDate: Date {
        // 30 days ago from today
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    private var maxSelectableDate: Date {
        // Far future — safe upper bound (2030)
        Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date.distantFuture
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
                        in: minSelectableDate...maxSelectableDate,  // ← Key change: past 30 days + future
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)  // Nice calendar view
                    
                    // Optional: Helpful hint for users
                    Text("Select any date in the last 30 days (for backtesting) or future (for forecasting)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 4)
                
                    
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

                        //  success alert
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
                        
                        .sheet(isPresented: $showingShareSheet) {
                            SharePredictionSheet(
                                modelName: model.name,
                                modelDescription: model.description,
                                predictionDate: selectedDate,
                                predictedPrice: predictedPrice ?? 4400.0,
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
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                Form {
                    Section("Adjust Your Prediction") {
                        TextField("Gold Price (USD)", value: $predictedPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                        
                        Text("Current spot price reference: ~$4,360 (Dec 31, 2025)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Edit Prediction")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEditSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingEditSheet = false
                            // Haptic feedback for satisfaction
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                        .disabled(predictedPrice == nil || predictedPrice! <= 0)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Prediction Failed", isPresented: $showingErrorAlert) {
            Button("OK") {
                // Optional: Could add retry logic here later
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Sub-views (for bettter complie time, too complicated nested view)
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
        VStack(spacing: 16) {
            Text("Prediction for \(selectedDate, format: .dateTime.month(.abbreviated).day().year())")
                .font(.title3)
                .foregroundStyle(.primary)
            
            if isLoadingPrediction {
                // Loading state (AI calling)
                ProgressView()
                    .scaleEffect(1.5)
                Text("Contacting AI model...")
                    .foregroundStyle(.secondary)
            } else if let price = predictedPrice {
                // AI or user has entered a price , show it and allow edit
                Button(action: {
                    showingEditSheet = true
                }) {
                    VStack(spacing: 8) {
                        Text("$\(price.formatted(.number.precision(.fractionLength(2))))")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.goldAccent)
                        
                        Text("Tap to adjust prediction")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.goldAccent.opacity(0.6), lineWidth: 3)
                            )
                            .shadow(color: Color.goldAccent.opacity(0.3), radius: 16, y: 8)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPredicting ? 1.15 : 1.0)
                .opacity(isPredicting ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.6), value: isPredicting)
            } else {
                // No prediction yet ,then invite user to enter manually orr use AI
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.goldAccent.opacity(0.4))
                    
                    Text("No prediction yet")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        Button("Enter Manual Prediction") {
                            showingEditSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.goldAccent)
                        
                        Text("or")
                            .foregroundStyle(.secondary)
                        
                        Button("Predict with AI") {
                            triggerPredictAnimation()
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.headline)
                }
                .padding(40)
            }
            
            if let error = predictionError {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .padding()
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
                predicted_price: predictedPrice ??  4400.0,
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
        // Start animation + haptic
        isPredicting = true
        shineAngle = 0
        particleScales = Array(repeating: 0, count: 8)
        
        withAnimation(.easeInOut(duration: 0.8)) {
            shineAngle = 360
            particleScales = Array(repeating: 1, count: 8)
        }
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        // Call real API
        Task {
            await predictFromAPI()
            
            // After API returns, stop animation
            withAnimation {
                isPredicting = false
            }
        }
    }
    // MARK: - Predict API call
    private func predictFromAPI() async {
        // Reset state
        await MainActor.run {
            isLoadingPrediction = true
            predictionError = nil
            predictedPrice = nil
        }
        
        // 1. Format date as YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        
        // 2. Map optimismBias to your mode
        var mode = 2  // Neutral default
        if optimismBias > 0 {
            mode = 1  // Optimistic
        } else if optimismBias < 0 {
            mode = 3  // Pessimistic
        }
        
        // 3. Prepare JSON body
        let requestBody = ["date": dateString, "mode": mode] as [String : Any]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            await MainActor.run { predictionError = "Failed to prepare request" }
            await MainActor.run { isLoadingPrediction = false }
            return
        }
        
        // 4. Use the model's API URL
        guard let url = URL(string: model.apiURL + "/api/predict/gold") else {
            await MainActor.run { predictionError = "Invalid API URL" }
            await MainActor.run { isLoadingPrediction = false }
            return
        }
        
        // 5. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15  // 15 seconds timeout , dont waitforever
        
        do {
            // 6. Perform network call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 7. Basic response check
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // 8. Decode JSON
            let decoded = try JSONDecoder().decode(PredictionResponse.self, from: data)
            
            // 9. Handle result
            if decoded.success, let price = decoded.predicted_price {
                await MainActor.run {
                    predictedPrice = price
                }
            } else {
                await MainActor.run {
                    alertMessage = decoded.error ?? "Server returned an error"
                    showingErrorAlert = true
                }
            }
            
        } catch {
            await MainActor.run {
                isLoadingPrediction = false
                
                //  user-friendly error messages
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        alertMessage = "Request timed out. Check your internet or try again later."
                    case .notConnectedToInternet:
                        alertMessage = "No internet connection. Please check your network."
                    case .badServerResponse:
                        alertMessage = "Server error. The AI model might be unavailable."
                    default:
                        alertMessage = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    alertMessage = "Prediction failed: \(error.localizedDescription)"
                }
                
                showingErrorAlert = true
                print("Prediction API error: \(error)")  // Keep for debugging
            }
        }
        
        await MainActor.run { isLoadingPrediction = false }
    }
    
}
struct PredictionResponse: Codable {
    let success: Bool
    let predicted_price: Double?
    let target_date: String?
    let mode: Int?
    let error: String?
    
    
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
