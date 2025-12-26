import SwiftUI

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
                            print("Saved to records")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.successAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button("Share") {
                            print("Sharing...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .listRowInsets(EdgeInsets())
                    
                    Button("Delete Model", role: .destructive) {
                        if !isDefaultModel {
                            showingDeleteAlert = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowInsets(EdgeInsets())
                    .disabled(isDefaultModel)
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
