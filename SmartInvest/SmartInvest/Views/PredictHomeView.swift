import SwiftUI

struct PredictHomeView: View {
    // MARK: - Default Official Predictor
    private let defaultPredictor = PredictorModel(
        name: "SmartInvest Default",
        description: "Official gold price predictor powered by advanced RNN model",
        apiURL: "https://your-flask-server.com/default-predict",
        isAutoPredictEnabled: true
    )
    
    // MARK: - User Predictors
    @State private var userPredictors: [PredictorModel] = []
    
    // MARK: - Combined Predictors
    private var allPredictors: [PredictorModel] {
        [defaultPredictor] + userPredictors
    }
    
    // MARK: - Gold Price State
    @State private var currentPrice: Double = 4503.68  // Fallback value
    @State private var yesterdayClose: Double = 4500.00 // Fallback
    @State private var isLoadingPrice = false
    @State private var priceError: String?
    
    // MARK: - Task Management (Prevents Cancellation Bugs)
    @State private var fetchTask: Task<Void, Never>? = nil
    
    // MARK: - Create Sheet State
    @State private var showingCreateSheet = false
    @State private var newModelName = ""
    @State private var newDescription = ""
    @State private var newApiURL = ""
    @State private var isAutoPredictEnabled = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Gold Price Header
                        goldPriceHeaderView
                            .padding(.horizontal)
                        
                        // Predictor Cards
                        ForEach(allPredictors) { model in
                            PredictorCardView(
                                model: model,
                                onDelete: {  // ← New closure
                                            if model.id != defaultPredictor.id {  // Protect default model
                                                userPredictors.removeAll { $0.id == model.id }
                                            }
                                        },
                                onEdit: { updatedModel in  // ← NEW
                                            if model.id != defaultPredictor.id {
                                                if let index = userPredictors.firstIndex(where: { $0.id == model.id }) {
                                                    userPredictors[index] = updatedModel
                                                }
                                            }
                                        }
                            
                            )
                                .padding(.horizontal)
                                .overlay {
                                    if model.id == defaultPredictor.id {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.primaryAccent, lineWidth: 3)
                                    }
                                }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
                .refreshable {
                    fetchGoldPrice()
                }
                
                // Floating + Button
                floatingCreateButton
            }
            .navigationTitle("Predict")
            .navigationBarTitleDisplayMode(.large)
            
            // Create Sheet
            .sheet(isPresented: $showingCreateSheet) {
                CreatePredictorSheet(
                    modelName: $newModelName,
                    description: $newDescription,
                    apiURL: $newApiURL,
                    isAutoPredictEnabled: $isAutoPredictEnabled,
                    onCreate: createNewModel
                )
            }
            
            // Initial Load
            .onAppear {
                fetchGoldPrice()
            }
            
            // Loading Overlay
            .overlay {
                if isLoadingPrice {
                    ProgressView("Updating gold price...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Error Alert
            .alert("Price Update Error", isPresented: Binding(get: { priceError != nil }, set: { if !$0 { priceError = nil } })) {
                Button("OK") {}
            } message: {
                Text(priceError ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Fetch Real Gold Price (Free & Reliable API)
    private func fetchGoldPrice() {
        fetchTask?.cancel()
        
        fetchTask = Task {
            await performFetch()
        }
    }
    
    @MainActor
    private func performFetch() async {
        isLoadingPrice = true
        priceError = nil
        
        guard let url = URL(string: "https://data-asg.goldprice.org/dbXRates/USD") else {
            priceError = "Invalid URL"
            isLoadingPrice = false
            return
        }
        
        do {
            try Task.checkCancellation()
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            try Task.checkCancellation()
            
            let response = try JSONDecoder().decode(GoldPriceResponse.self, from: data)
            
            guard let firstItem = response.items?.first else {
                priceError = "No price data available"
                isLoadingPrice = false
                return
            }

            let price = firstItem.xauPrice  // Now safe — firstItem is non-optional

            yesterdayClose = currentPrice
            currentPrice = price
            
        } catch is CancellationError {
            print("Gold price fetch cancelled (normal)")
        } catch {
            priceError = "Network error: \(error.localizedDescription)"
            print("Gold price fetch failed: \(error)")
        }
        
        isLoadingPrice = false
    }
    
    // MARK: - API Response Models
    private struct GoldPriceResponse: Decodable {
        let items: [GoldItem]?
    }
    
    private struct GoldItem: Decodable {
        let xauPrice: Double
        // Other fields ignored
    }
    
    // MARK: - Gold Price Header View
    private var goldPriceHeaderView: some View {
        VStack(spacing: 12) {
            Text("Current Gold Price (XAU/USD)")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            if isLoadingPrice {
                ProgressView()
                    .scaleEffect(1.2)
            } else {
                Text("$\(currentPrice.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.goldAccent)
            }
            
            HStack(spacing: 16) {
                VStack {
                    Text("Yesterday Close")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text("$\(yesterdayClose.formatted(.number.precision(.fractionLength(2))))")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }
                
                VStack {
                    Text("24h Change")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    let change = currentPrice - yesterdayClose
                    let percent = yesterdayClose > 0 ? (change / yesterdayClose) * 100 : 0
                    
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(change >= 0 ? Color.successAccent : .red)
                        
                        Text("\(change >= 0 ? "+" : "")\(change.formatted(.number.precision(.fractionLength(2))))")
                            .font(.title3.bold())
                            .foregroundStyle(change >= 0 ? Color.successAccent : .red)
                        
                        Text("(\(percent >= 0 ? "+" : "")\(percent.formatted(.number.precision(.fractionLength(2))))%)")
                            .font(.headline)
                            .foregroundStyle(change >= 0 ? Color.successAccent : .red)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.goldAccent.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color.goldAccent.opacity(0.4), radius: 12, y: 8)
    }
    
    // MARK: - Floating Create Button
    private var floatingCreateButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    newModelName = ""
                    newDescription = ""
                    newApiURL = ""
                    isAutoPredictEnabled = true
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .background(Color.primaryAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.primaryAccent.opacity(0.6), radius: 10, y: 5)
                }
                .padding(24)
            }
        }
    }
    
    // MARK: - Create New Model
    private func createNewModel() {
        let newModel = PredictorModel(
            name: newModelName.trimmingCharacters(in: .whitespaces),
            description: newDescription.trimmingCharacters(in: .whitespaces),
            apiURL: newApiURL.trimmingCharacters(in: .whitespaces),
            isAutoPredictEnabled: isAutoPredictEnabled
        )
        
        userPredictors.append(newModel)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Previews
#Preview {
    PredictHomeView()
}

#Preview("Dark Mode") {
    PredictHomeView()
        .preferredColorScheme(.dark)
}
