import SwiftUI
import Supabase
//this is the predictor ai model list page, user can use, view, delete ai model profile
struct PredictHomeView: View {
    // MARK: - Default Official Predictor
    // our training ai model, this default ai model can not be modify and delete by other user
    private let defaultPredictor = PredictorModel(
        name: "SmartInvest Default",
        description: "Official gold price predictor powered by advanced RNN model",
        apiURL: "http://192.168.0.213:5000",
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
    @State private var yesterdayClose: Double? = nil  // Optional value wuntil fetched
    @State private var isLoadingYesterday = false
    @State private var yesterdayError: String?
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
            ContentView(
                allPredictors: allPredictors,
                defaultPredictorID: defaultPredictor.id,
                currentPrice: currentPrice,
                isLoadingPrice: isLoadingPrice,
                yesterdayClose: yesterdayClose,
                isLoadingYesterday: isLoadingYesterday,
                goldPriceHeaderView: AnyView(goldPriceHeaderView),  // Erase type
                onCreateNew: {
                    newModelName = ""
                    newDescription = ""
                    newApiURL = ""
                    isAutoPredictEnabled = true
                    showingCreateSheet = true
                },
                onDelete: { id in
                    userPredictors.removeAll { $0.id == id }
                },
                onEdit: { updatedModel in
                    if let index = userPredictors.firstIndex(where: { $0.id == updatedModel.id }) {
                        userPredictors[index] = updatedModel
                    }
                }
            )
            .refreshable {
                fetchGoldPrice()
                await fetchYesterdayClose()
            }
            .navigationTitle("Predict")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateSheet) {
                CreatePredictorSheet(
                    modelName: $newModelName,
                    description: $newDescription,
                    apiURL: $newApiURL,
                    isAutoPredictEnabled: $isAutoPredictEnabled,
                    onCreate: createNewModel
                )
            }
            .onAppear {
                fetchGoldPrice()
                Task { await fetchYesterdayClose() }
            }
            .overlay {
                if isLoadingPrice {
                    ProgressView("Updating gold price...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Price Update Error", isPresented: Binding(get: { priceError != nil }, set: { if !$0 { priceError = nil } })) {
                Button("OK") {}
            } message: {
                Text(priceError ?? "Unknown error")
            }
        }
    }
    // MARK: - Current Price Section
    private struct CurrentPriceSection: View {
        let currentPrice: Double
        let isLoadingPrice: Bool
        
        var body: some View {
            VStack(spacing: 8) {
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
            }
        }
    }
    // MARK: - Main Content (seprate the content view, for better complie time when build)
    private struct ContentView: View {
        let allPredictors: [PredictorModel]
        let defaultPredictorID: UUID  // To protect default in ForEach
        
        let currentPrice: Double
        let isLoadingPrice: Bool
        
        let yesterdayClose: Double?
        let isLoadingYesterday: Bool
        
        let goldPriceHeaderView: AnyView  // pass the header as AnyView
        
        
        let onCreateNew: () -> Void
        let onDelete: (UUID) -> Void
        let onEdit: (PredictorModel) -> Void
        
        var body: some View {
            ZStack {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        goldPriceHeaderView
                            .padding(.horizontal)
                        
                        ForEach(allPredictors) { model in
                            PredictorCardView(
                                model: model,
                                onDelete: {
                                    if model.id != defaultPredictorID {
                                        onDelete(model.id)
                                    }
                                },
                                onEdit: { updatedModel in
                                    if model.id != defaultPredictorID {
                                        onEdit(updatedModel)
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .overlay {
                                if model.id == defaultPredictorID {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primaryAccent, lineWidth: 3)
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
                
                // Floating + Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onCreateNew) {
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
        }
    }

    // MARK: - Yesterday Close Section
    private struct YesterdayCloseSection: View {
        let yesterdayClose: Double?
        let isLoadingYesterday: Bool
        
        var body: some View {
            VStack {
                Text("Yesterday Close")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                if isLoadingYesterday {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let yesterday = yesterdayClose {
                    Text("$\(yesterday.formatted(.number.precision(.fractionLength(2))))")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                } else {
                    Text("Unavailable")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 24h Change Section
    private struct ChangeSection: View {
        let currentPrice: Double
        let yesterdayClose: Double?
        
        var body: some View {
            VStack {
                Text("24h Change")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                let base = yesterdayClose ?? currentPrice
                let change = currentPrice - base
                let percent = base > 0 ? (change / base) * 100 : 0
                
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
            .padding(.top, 8)
        }
    }
    // MARK: - Fetch yesterday gold price from supabase
    private func fetchYesterdayClose() async {
        await MainActor.run {
            isLoadingYesterday = true
            yesterdayError = nil
        }
        
        do {
            // Fetch the latest record (most recent date)
            let latestRecords: [DailyGoldPrice] = try await SupabaseManager.shared.client
                .from("daily_gold_prices")
                .select("date, close_price")
                .order("date", ascending: false)  // Newest first
                .limit(1)                         // Only need the latest, so only the first one
                .execute()
                .value
            
            guard let latest = latestRecords.first else {
                throw NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No historical data found"])
            }
            
            await MainActor.run {
                yesterdayClose = latest.close_price
            }
            
            print("Fetched yesterday close from Supabase: $\(latest.close_price) on \(latest.date)")
            
        } catch {
            await MainActor.run {
                yesterdayError = "Failed to load yesterday's price"
                print("Supabase yesterday fetch error: \(error)")
                // Fallback to previous currentPrice if available (your existing logic)
                yesterdayClose = yesterdayClose ?? 4400.0
            }
        }
        
        await MainActor.run { isLoadingYesterday = false }
    }
    
    // MARK: - Fetch Real Gold Price (Free external api)
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

            let price = firstItem.xauPrice  // firstItem is non-optional

            //yesterdayClose = currentPrice
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
            CurrentPriceSection(currentPrice: currentPrice, isLoadingPrice: isLoadingPrice)
            
            HStack(spacing: 16) {
                YesterdayCloseSection(yesterdayClose: yesterdayClose, isLoadingYesterday: isLoadingYesterday)
                
                ChangeSection(currentPrice: currentPrice, yesterdayClose: yesterdayClose)
            }
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
