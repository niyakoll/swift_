import SwiftUI

struct RecordView: View {
    // MARK: - All Models (Default + User-Created)
    // For prototype, we'll use the same models as Predict tab
    // In real app, fetch from same source as PredictHomeView
    private let allModels: [PredictorModel] = [
        PredictorModel(
            name: "SmartInvest Default",
            description: "Official RNN model",
            apiURL: "https://example.com",
            isAutoPredictEnabled: true
        ),
        PredictorModel(
            name: "My Gold Pro",
            description: "Custom high-accuracy model",
            apiURL: "https://my-server.com",
            isAutoPredictEnabled: true
        ),
        PredictorModel(
            name: "Volatility Master",
            description: "Optimized for market swings",
            apiURL: "https://pro.com",
            isAutoPredictEnabled: false
        )
    ]
    
    // MARK: - Mock Records (Generated for each model)
    private var mockRecords: [UUID: [PredictionRecord]] {
        var records: [UUID: [PredictionRecord]] = [:]
        
        for model in allModels {
            var modelRecords: [PredictionRecord] = []
            
            let count = Int.random(in: 15...30)
            let basePrice = 4500.0
            
            for i in 0..<count {
                let daysAgo = Int.random(in: 1...180)
                let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
                let dateString = ISO8601DateFormatter().string(from: date).prefix(10) // "YYYY-MM-DD"
                
                let randomChange = Double.random(in: -100...100)
                let predicted = basePrice + randomChange + Double(i * 5)
                
                let actualNoise = Double.random(in: -50...50)
                let actual = predicted + actualNoise
                
                let record = PredictionRecord(
                    id: nil,                    // Supabase will fill
                    created_at: Date(),         // Mock creation time
                    user_id: UUID(),            // Mock user
                    user_email: "mock@example.com",
                    model_id: model.id,
                    model_name: model.name,
                    prediction_date: String(dateString),
                    predicted_price: predicted,
                    optimism_bias: Double.random(in: -20...20),
                    actualPrice: actual
                )
                
                modelRecords.append(record)
            }
            
            records[model.id] = modelRecords
        }
        
        return records
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                
                if allModels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                        
                        Text("No models yet")
                            .font(.title2.bold())
                            .foregroundStyle(Color.textSecondary)
                        
                        Text("Go to Predict tab to create your first model")
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(allModels) { model in
                                NavigationLink(destination: RecordDetailView(
                                    model: model,
                                    records: mockRecords[model.id] ?? []
                                )) {
                                    RecordModelCard(
                                        model: model,
                                        records: mockRecords[model.id] ?? []
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())  // Keeps card animation
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Records")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Model Card in Record List
struct RecordModelCard: View {
    let model: PredictorModel
    let records: [PredictionRecord]
    
    // MARK: - Summary Stats
    private var totalPredictions: Int {
        records.count
    }
    
    private var dateRange: String {
        guard let first = records.min(by: { $0.prediction_date < $1.prediction_date }),
              let last = records.max(by: { $0.prediction_date < $1.prediction_date }) else {
            return "No predictions"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let firstDate = formatter.date(from: first.prediction_date) ?? Date()
        let lastDate = formatter.date(from: last.prediction_date) ?? Date()
        
        return "\(formatter.string(from: firstDate)) – \(formatter.string(from: lastDate))"
    }
    
    private var overallAccuracy: Double {
        let pastRecords = records.filter { !$0.isFuture }
        guard !pastRecords.isEmpty else { return 0 }
        
        let accuracies = pastRecords.compactMap { $0.accuracy }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon (same as Predict tab)
            ZStack {
                Circle()
                    .fill(model.name == "SmartInvest Default" ? Color.primaryAccent : Color.goldAccent.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if model.name == "SmartInvest Default" {
                    Image(systemName: "brain")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                } else {
                    Text(String(model.name.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(model.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "number")
                        Text("\(totalPredictions) predictions")
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(dateRange)
                    }
                    
                    HStack {
                        Image(systemName: "target")
                        Text("Accuracy: \(String(format: "%.1f", overallAccuracy))%")
                            .foregroundStyle(overallAccuracy > 70 ? Color.successAccent : overallAccuracy > 50 ? .orange : .red)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.textSecondary.opacity(0.6))
        }
        .padding(20)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderSeparator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Preview
#Preview {
    RecordView()
}
