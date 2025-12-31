import SwiftUI
import Supabase
struct RecordView: View {
    @State private var modelRecords: [String: [PredictionRecord]] = [:]  // model_name → records
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingDeleteModelAlert = false
    @State private var modelToDelete: String?
    
    private func deleteModelRecords(_ modelName: String) {
        modelToDelete = modelName
        showingDeleteModelAlert = true
    }

    private func performDeleteModelRecords() async {
        guard let modelName = modelToDelete else { return }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            
            try await SupabaseManager.shared.client
                .from("prediction_records")
                .delete()
                .eq("user_id", value: user.id)
                .eq("model_name", value: modelName)
                .execute()
            
            print("Deleted all records for model: \(modelName)")
            
            // Remove from local state
            modelRecords.removeValue(forKey: modelName)
            
        } catch {
            print("Delete failed: \(error)")
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading your records...")
                        .font(.title3)
                        .foregroundStyle(Color.textSecondary)
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        
                        Text("Failed to load records")
                            .font(.title2.bold())
                        
                        Text(error)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task { await loadRecords() }
                        }
                        .padding()
                        .background(Color.primaryAccent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if modelRecords.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                        
                        Text("No records yet")
                            .font(.title2.bold())
                            .foregroundStyle(Color.textSecondary)
                        
                        Text("Make predictions and save them to see performance")
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(modelRecords.keys.sorted()), id: \.self) { modelName in
                                let records = modelRecords[modelName] ?? []
                                
                                NavigationLink(destination: RecordDetailView(
                                    model: PredictorModel(
                                        name: modelName,
                                        description: "",
                                        apiURL: "",
                                        isAutoPredictEnabled: true
                                    ),
                                    records: records
                                )) {
                                    RecordModelCard(
                                        modelName: modelName,
                                        records: records,
                                        onDelete: {
                                            if modelName != "SmartInvest Default" {
                                                deleteModelRecords(modelName)
                                                
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        await loadRecords()
                    }
                }
            }
            .navigationTitle("Records")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await loadRecords() }
            }
            .alert("Delete Model Records?", isPresented: $showingDeleteModelAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await performDeleteModelRecords()
                    }
                }
            } message: {
                Text("This will permanently delete ALL predictions for '\(modelToDelete ?? "")'. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Fetch Real Records from Supabase
    private func loadRecords() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            
            // Fetch prediction records
            let fetchedRecords: [PredictionRecord] = try await SupabaseManager.shared.client
                .from("prediction_records")
                .select()
                .eq("user_id", value: user.id)
                .order("prediction_date", ascending: false)
                .execute()
                .value
            
            // Fetch all daily gold prices
            let dailyPrices: [DailyGoldPrice] = try await SupabaseManager.shared.client
                .from("daily_gold_prices")
                .select("date, close_price")
                .execute()
                .value
            
            // Create lookup map: date string → close price
            let priceMap = Dictionary(uniqueKeysWithValues: dailyPrices.map { ($0.date, $0.close_price) })
            
            // Enrich records with actual price
            var enrichedRecords = fetchedRecords
            for i in 0..<enrichedRecords.count {
                if let actual = priceMap[enrichedRecords[i].prediction_date] {
                    enrichedRecords[i].actualPrice = actual
                }
            }
            
            // Group by model_name
            var grouped: [String: [PredictionRecord]] = [:]
            for record in enrichedRecords {
                grouped[record.model_name, default: []].append(record)
            }
            
            modelRecords = grouped
            
        } catch {
            errorMessage = "Could not load records"
            print("Fetch failed: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Model Card (Simplified for Real Data)
struct RecordModelCard: View {
    let modelName: String
    let records: [PredictionRecord]
    let onDelete: () -> Void  // Callback to parent
    
    private var totalPredictions: Int { records.count }
    
    private var dateRange: String {
        guard let first = records.min(by: { $0.prediction_date < $1.prediction_date }),
              let last = records.max(by: { $0.prediction_date < $1.prediction_date }) else {
            return "No predictions"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(first.displayDate) – \(last.displayDate)"
    }
    
    private var overallAccuracy: Double {
        let pastRecords = records.filter { !$0.isFuture }
        let validRecords = pastRecords.filter { $0.actualPrice != nil }
        guard !validRecords.isEmpty else { return 0 }
        
        let accuracies = validRecords.map { record in
            let actual = record.actualPrice!
            let diff = abs(record.predicted_price - actual)
            let accuracy = 100 - (diff / actual * 100)
            return max(0, min(100, accuracy))
        }
        
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.goldAccent.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Text(String(modelName.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.goldAccent)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(modelName)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Image(systemName: "number"); Text("\(totalPredictions) predictions") }
                        HStack { Image(systemName: "calendar"); Text(dateRange) }
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
            
            // MARK: Delete Button (only for non-default models)
            if modelName != "SmartInvest Default" {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .background(Circle().fill(Color.backgroundSecondary))
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RecordView()
}
