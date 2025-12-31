import SwiftUI
import Supabase
struct CommunityView: View {
    @State private var posts: [EnrichedCommunityPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var sortOption: SortOption = .postTime
    @State private var selectedFilterDate: Date? = nil  // nil = All Dates
    @State private var showingDatePicker = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundSecondary
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading community...")
                        .font(.title3)
                        .foregroundStyle(Color.textSecondary)
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        
                        Text("Failed to load posts")
                            .font(.title2.bold())
                        
                        Text(error)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task { await loadCommunityData() }
                        }
                        .padding()
                        .background(Color.primaryAccent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if posts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                        
                        Text("Community is quiet")
                            .font(.title2.bold())
                            .foregroundStyle(Color.textSecondary)
                        
                        Text("Be the first to share your prediction!")
                            .foregroundStyle(Color.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            Section {
                                // MARK: - Sort Picker
                                Picker("Sort By", selection: $sortOption) {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                
                                // MARK: - Date Filter
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(Color.primaryAccent)
                                    
                                    if let date = selectedFilterDate {
                                        Text(date, format: .dateTime.month(.abbreviated).day().year())
                                            .font(.headline)
                                    } else {
                                        Text("All Dates")
                                            .font(.headline)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(selectedFilterDate == nil ? "Filter" : "Clear") {
                                        if selectedFilterDate != nil {
                                            selectedFilterDate = nil
                                        } else {
                                            showingDatePicker = true
                                        }
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.primaryAccent)
                                }
                                .padding()
                                .background(Color.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.borderSeparator, lineWidth: 1)
                                )
                                .onTapGesture {
                                    showingDatePicker = true
                                }
                                
                                // MARK: - Date Picker Sheet
                                .sheet(isPresented: $showingDatePicker) {
                                    NavigationStack {
                                        VStack {
                                            DatePicker(
                                                "Select Prediction Date",
                                                selection: Binding(
                                                    get: { selectedFilterDate ?? Date() },
                                                    set: { selectedFilterDate = $0 }
                                                ),
                                                displayedComponents: .date
                                            )
                                            .datePickerStyle(.graphical)
                                            .padding()
                                            
                                            Spacer()
                                        }
                                        .navigationTitle("Filter by Date")
                                        .navigationBarTitleDisplayMode(.inline)
                                        .toolbar {
                                            ToolbarItem(placement: .cancellationAction) {
                                                Button("Cancel") { showingDatePicker = false }
                                            }
                                            ToolbarItem(placement: .confirmationAction) {
                                                Button("Apply") { showingDatePicker = false }
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                    }
                                    .presentationDetents([.medium])
                                }
                                
                                // MARK: - Posts List
                                ForEach(filteredAndSortedPosts) { enrichedPost in
                                    CommunityPostCard(enrichedPost: enrichedPost)
                                        .padding(.horizontal)
                                }
                                
                                if filteredAndSortedPosts.isEmpty && selectedFilterDate != nil {
                                    VStack(spacing: 20) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.system(size: 60))
                                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                                        
                                        Text("No predictions for this date")
                                            .font(.title2.bold())
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadCommunityData()
            }
            .onAppear {
                Task { await loadCommunityData() }
            }
        }
    }
    
    // MARK: - Load Posts + Actual Prices
    private func loadCommunityData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch raw posts
            let rawPosts: [CommunityPost] = try await SupabaseManager.shared.client
                .from("community_posts")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Fetch all daily prices (once)
            let dailyPrices: [DailyGoldPrice] = try await SupabaseManager.shared.client
                .from("daily_gold_prices")
                .select("date, close_price")
                .execute()
                .value
            
            // Create dictionary for fast lookup: date string -> price
            let priceMap = Dictionary(uniqueKeysWithValues: dailyPrices.map { ($0.date, $0.close_price) })
            
            // Enrich posts with actual price
            let enriched = rawPosts.map { post -> EnrichedCommunityPost in
                let actual = priceMap[post.prediction_date]
                return EnrichedCommunityPost(
                    post: post,
                    actualPrice: actual
                )
            }
            
            posts = enriched
            
        } catch {
            errorMessage = "Could not load community data"
            print("Load failed: \(error)")
        }
        
        isLoading = false
    }
    private var sortedPosts: [EnrichedCommunityPost] {
        posts.sorted { post1, post2 in
            switch sortOption {
            case .accuracy:
                // Future posts go to bottom
                if post1.isFuture != post2.isFuture {
                    return !post1.isFuture  // Past posts first
                }
                // For past posts: higher accuracy first
                guard let acc1 = post1.accuracy, let acc2 = post2.accuracy else {
                    return post1.post.created_at! > post2.post.created_at!
                }
                return acc1 > acc2
                
            case .predictionDate:
                // Parse prediction_date string
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date1 = formatter.date(from: post1.post.prediction_date) ?? Date.distantPast
                let date2 = formatter.date(from: post2.post.prediction_date) ?? Date.distantPast
                return date1 > date2  // Newest prediction date first
                
            case .postTime:
                return post1.post.created_at! > post2.post.created_at!  // Newest post first
            }
        }
    }
    private var filteredPosts: [EnrichedCommunityPost] {
        if let filterDate = selectedFilterDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filterString = formatter.string(from: filterDate)
            
            return sortedPosts.filter { $0.post.prediction_date == filterString }
        } else {
            return sortedPosts
        }
    }
    private var filteredAndSortedPosts: [EnrichedCommunityPost] {
        var result = posts
        
        // Apply filter first
        if let filterDate = selectedFilterDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filterString = formatter.string(from: filterDate)
            result = result.filter { $0.post.prediction_date == filterString }
        }
        
        // Then apply sort
        return result.sorted { post1, post2 in
            switch sortOption {
            case .accuracy:
                if post1.isFuture != post2.isFuture {
                    return !post1.isFuture
                }
                guard let acc1 = post1.accuracy, let acc2 = post2.accuracy else {
                    return post1.post.created_at! > post2.post.created_at!
                }
                return acc1 > acc2
                
            case .predictionDate:
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date1 = formatter.date(from: post1.post.prediction_date) ?? Date.distantPast
                let date2 = formatter.date(from: post2.post.prediction_date) ?? Date.distantPast
                return date1 > date2
                
            case .postTime:
                return post1.post.created_at! > post2.post.created_at!
            }
        }
    }
}

// MARK: - Enriched Post (With Actual Price)
struct EnrichedCommunityPost: Identifiable {
    let id = UUID()
    let post: CommunityPost
    let actualPrice: Double?
    
    var accuracy: Double? {
        guard let actual = actualPrice, actual > 0 else { return nil }
        let diff = abs(post.predicted_price - actual)
        let accuracy = 100 - (diff / actual * 100)
        return max(0, min(100, accuracy))
    }
    
    var isFuture: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let predDate = formatter.date(from: post.prediction_date) else { return true }
        // Compare predDate with TODAY (not tomorrow)
        let today = Calendar.current.startOfDay(for: Date())
        let predictionDay = Calendar.current.startOfDay(for: predDate)
        return predictionDay >= today  // Today or future = pending
    }
    
    var accuracyColor: Color {
        guard let acc = accuracy else { return .green }
        // Gradient: 100% = deep gold, 0% = light gold
        let ratio = acc / 100
        return Color(
            red: 0.85 + ratio * 0.15,   // More red/orange for better accuracy
            green: 0.65 + ratio * 0.35,
            blue: 0.0
        )
    }
}



// MARK: - Updated Post Card
struct CommunityPostCard: View {
    let enrichedPost: EnrichedCommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack {
                Circle()
                    .fill(Color.primaryAccent.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(enrichedPost.post.username?.prefix(1).uppercased() ?? "A")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primaryAccent)
                    )
                
                VStack(alignment: .leading) {
                    Text(enrichedPost.post.username ?? "Anonymous")
                        .font(.headline)
                    
                    Text(enrichedPost.post.displayDate)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
            }
            
            // Accuracy Badge
            HStack {
                Image(systemName: enrichedPost.isFuture ? "clock" : "checkmark.circle")
                    .foregroundStyle(enrichedPost.isFuture ? .green : enrichedPost.accuracyColor)
                
                Text(enrichedPost.isFuture ? "Pending Verification" : "Accuracy: \(String(format: "%.1f", enrichedPost.accuracy ?? 0))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(enrichedPost.isFuture ? .green : enrichedPost.accuracyColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(enrichedPost.isFuture ? Color.green.opacity(0.2) : enrichedPost.accuracyColor.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Prediction Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Predicted for: \(enrichedPost.post.predictionDateFormatted)")
                    .font(.subheadline)
                    .foregroundStyle(Color.goldAccent)
                
                HStack {
                    Text("Model:")
                    Text(enrichedPost.post.model_name)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Predicted Price:")
                    Text("$\(enrichedPost.post.predicted_price.formatted(.number.precision(.fractionLength(2))))")
                        .font(.title3.bold())
                        .foregroundStyle(Color.goldAccent)
                }
                
                if let actual = enrichedPost.actualPrice {
                    HStack {
                        Text("Actual Price:")
                        Text("$\(actual.formatted(.number.precision(.fractionLength(2))))")
                            .foregroundStyle(.primary)
                    }
                    
                    let diff = enrichedPost.post.predicted_price - actual
                    Text(diff >= 0 ? "Over by $\(abs(diff).formatted(.number.precision(.fractionLength(2))))" : "Under by $\(abs(diff).formatted(.number.precision(.fractionLength(2))))")
                        .foregroundStyle(diff >= 0 ? .orange : .blue)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Opinion
            Text(enrichedPost.post.opinion)
                .font(.body)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderSeparator, lineWidth: 1)
        )
    }
}

enum SortOption: String, CaseIterable {
    case accuracy = "Accuracy"
    case predictionDate = "Prediction Date"
    case postTime = "Post Time"
}
// MARK: - Preview
#Preview {
    CommunityView()
}
