import SwiftUI
import Charts
import PDFKit  // ← Add this
import Supabase
struct RecordDetailView: View {
    let model: PredictorModel
    @State var records: [PredictionRecord]
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var showingDeleteRecordAlert = false
    @State private var recordToDelete: PredictionRecord?
    @State private var selectedTimeRange: TimeRange = .week7
    private func deleteSingleRecord(_ record: PredictionRecord) {
        recordToDelete = record
        showingDeleteRecordAlert = true
    }
    private func performDeleteRecord() async {
        guard let record = recordToDelete else { return }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            
            try await SupabaseManager.shared.client
                .from("prediction_records")
                .delete()
                .eq("id", value: String(record.id!))
                .eq("user_id", value: user.id)
                .execute()
            
            print("Deleted record for \(record.prediction_date)")
            
            // Remove from local array
            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records.remove(at: index)
            }
            
        } catch {
            print("Delete record failed: \(error)")
        }
    }
    // MARK: - Summary
    private var summary: ModelSummary {
        ModelSummary(from: records)
    }
    
    // MARK: - Sorted Records
    private var sortedRecords: [PredictionRecord] {
        records.sorted(using: KeyPathComparator(\.parsedDate, order: .reverse))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Summary Card
                    SummarySection(summary: summary)
                        .padding(.horizontal)
                    
                    // MARK: Line Chart
                    if !records.isEmpty {
                        PriceChartSection(records: sortedRecords, selectedTimeRange: $selectedTimeRange)
                            .padding(.horizontal)
                    }
                    
                    // MARK: Individual Records
                    IndividualRecordsSection(
                        records: sortedRecords,
                        onDeleteRecord: { record in
                            recordToDelete = record
                            showingDeleteRecordAlert = true
                        }
                    )
                    .alert("Delete This Prediction?", isPresented: $showingDeleteRecordAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            Task {
                                await performDeleteRecord()
                                // Refresh records after delete
                                // For now, we can reload from parent or use @ObservedObject later
                            }
                        }
                    } message: {
                        Text("This will permanently delete the prediction for \(recordToDelete?.displayDate ?? ""). This cannot be undone.")
                    }
                }
                .padding(.top)
            }
            .navigationTitle(model.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        pdfURL = generatePDF()
                        if pdfURL != nil {
                            showingShareSheet = true
                        }
                    }
                    .fontWeight(.semibold)
                    .sheet(isPresented: $showingShareSheet) {
                        if let url = pdfURL {
                            ActivityView(activityItems: [url])
                        }
                    }
                }
            }
        }
    }
    // MARK: - Generate PDF (Fixed – Works with Charts)
    private func generatePDF() -> URL? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.label
            ]
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let statLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let statValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
            
            // Title
            model.name.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
            
            // Subtitle
            "Performance Summary".draw(at: CGPoint(x: 40, y: 90), withAttributes: subtitleAttributes)
            
            // Summary Stats
            var yPosition: CGFloat = 130
            
            let stats = [
                ("Total Predictions", "\(summary.totalPredictions)"),
                ("Date Range", summary.dateRange),
                ("Overall Accuracy", summary.overallAccuracy),
                ("Average Error", summary.averageError),
                ("Best Prediction", summary.bestPrediction),
                ("Worst Prediction", summary.worstPrediction),
                ("Win Rate", summary.winRate),
                ("Pending", "\(summary.pendingPredictions)")
            ]
            
            for (label, value) in stats {
                label.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: statLabelAttributes)
                value.draw(at: CGPoint(x: 300, y: yPosition), withAttributes: statValueAttributes)
                yPosition += 50
            }
            
            // MARK: Render Chart as Image
            if !records.isEmpty {
                let chartView = PriceChartSection(records: sortedRecords, selectedTimeRange: $selectedTimeRange)
                    .frame(height: 400)
                    .padding()
                
                let hosting = UIHostingController(rootView: chartView)
                hosting.view.backgroundColor = UIColor.systemBackground
                
                // Size the view
                hosting.view.bounds = CGRect(x: 0, y: 0, width: 515, height: 400)
                hosting.view.sizeToFit()
                
                // Render to image
                let renderer = UIGraphicsImageRenderer(size: hosting.view.bounds.size)
                let chartImage = renderer.image { _ in
                    hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
                }
                
                // Draw image in PDF
                chartImage.draw(at: CGPoint(x: 40, y: yPosition + 20))
            }
            
            // Footer
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium
            "Exported on \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: 40, y: 800), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
        }
        
        // Save file
        let fileName = "SmartInvest_\(model.name.replacingOccurrences(of: " ", with: "_"))_\(Date().toString("yyyyMMdd_HHmm")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("PDF save error: \(error)")
            return nil
        }
    }
}

// MARK: - Summary Section (Improved Layout + Icons)
private struct SummarySection: View {
    let summary: ModelSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Summary")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                SummaryRow(icon: "number.circle.fill", label: "Total Predictions", value: "\(summary.totalPredictions)", color: .primary)
                SummaryRow(icon: "calendar.circle.fill", label: "Date Range", value: summary.dateRange, color: .blue)
                SummaryRow(icon: "target", label: "Overall Accuracy", value: summary.overallAccuracy, color: .goldAccent)
                SummaryRow(icon: "dollarsign.circle.fill", label: "Average Error", value: summary.averageError, color: .orange)
                SummaryRow(icon: "star.circle.fill", label: "Best Prediction", value: summary.bestPrediction, color: .green)
                SummaryRow(icon: "exclamationmark.circle.fill", label: "Worst Prediction", value: summary.worstPrediction, color: .red)
                SummaryRow(icon: "trophy.fill", label: "Win Rate", value: summary.winRate, color: .purple)
                SummaryRow(icon: "clock.fill", label: "Pending", value: "\(summary.pendingPredictions)", color: .secondary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
// MARK: - Reusable Summary Row with Icon
private struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
// MARK: - Price Chart Section
struct PriceChartSection: View {
    let records: [PredictionRecord]
    @Binding var selectedTimeRange: TimeRange
    
    // Sorted and filtered by selected range (oldest → newest)
    private var filteredAndSortedRecords: [PredictionRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let filtered = records.compactMap { record -> PredictionRecord? in
            guard let recordDate = record.parsedDate else { return nil }  // Safe skip if bad date
            
            let daysAgo: Int
            switch selectedTimeRange {
            case .week7:  daysAgo = 7
            case .month30: daysAgo = 30
            }
            
            let cutoffDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return recordDate >= cutoffDate ? record : nil
        }
        
        return filtered.sorted { $0.parsedDate! < $1.parsedDate! }  // Safe: we filtered nil dates
    }
    // MARK: - Dynamic Y-Axis Domain with Padding
        private var yAxisMin: Double {
            let allPrices = filteredAndSortedRecords.flatMap { record -> [Double] in
                var prices: [Double] = [record.predicted_price]
                if let actual = record.actualPrice {
                    prices.append(actual)
                }
                return prices
            }
            
            guard let minPrice = allPrices.min() else { return 4000 }  // fallback
            return minPrice - 150  // Add $150 buffer below lowest price
        }
        
        private var yAxisMax: Double {
            let allPrices = filteredAndSortedRecords.flatMap { record -> [Double] in
                var prices: [Double] = [record.predicted_price]
                if let actual = record.actualPrice {
                    prices.append(actual)
                }
                return prices
            }
            
            guard let maxPrice = allPrices.max() else { return 4800 }  // fallback
            return maxPrice + 150  // Add $150 buffer above highest price
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Over Time")
                .font(.title2.bold())
            
            // Segmented Picker for time range
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in  // ← Fixed with id: \.self
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            // The Chart with two lines
            Chart {
                // Predicted Price Line → Gold/Yellow
                ForEach(filteredAndSortedRecords) { record in
                    LineMark(
                        x: .value("Date", record.parsedDate!),  // Safe non-optional now
                        y: .value("Price", record.predicted_price),
                        series:.value("Type","Prediction")
                    )
                    .foregroundStyle(Color.goldAccent)
                    .symbol(Circle())
                }
                
                // Actual Price Line → Blue (only past dates)
                ForEach(filteredAndSortedRecords.filter { $0.actualPrice != nil }) { record in
                    LineMark(
                        x: .value("Date", record.parsedDate!),
                        y: .value("Price", record.actualPrice!),
                        series:.value("Type","Actual")
                    )
                    .foregroundStyle(Color.blue)
                    .symbol(Circle())
                }
            }
            .chartYScale(domain: yAxisMin ... yAxisMax)
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .dailyXAxis()
            .chartLegend(position: .top, alignment: .center) {
                HStack(spacing: 24) {
                    LegendItem(color: Color.goldAccent, label: "Predicted")
                    LegendItem(color: .blue, label: "Actual")
                }
            }
            .frame(height: 300)
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
}
// MARK: - Custom Daily X-Axis (Extracted to fix type-check timeout)
private struct DailyXAxis: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    
                    
                    
                    
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
    }
}

// Helper extension to use it cleanly
extension View {
    func dailyXAxis() -> some View {
        modifier(DailyXAxis())
    }
}
    



// MARK: - Legend Item
private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
        }
    }
}


// MARK: - Individual Records Section (with Swipe Delete)
struct IndividualRecordsSection: View {
    let records: [PredictionRecord]
    let onDeleteRecord: (PredictionRecord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Individual Predictions")
                .font(.title3.bold())
                .padding(.horizontal)
            
            ForEach(records) { record in
                PredictionRow(
                    record: record,
                    onDelete: { onDeleteRecord(record) }  // ← Pass the callback
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDeleteRecord(record)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Single Row
struct PredictionRow: View {
    let record: PredictionRecord
    let onDelete: () -> Void  // ← New callback
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main content
            HStack {
                VStack(alignment: .leading) {
                    Text(record.displayDate)
                        .font(.headline)
                    
                    Text("Predicted: $\(record.predicted_price.formatted(.number.precision(.fractionLength(2))))")
                        .foregroundStyle(Color.goldAccent)
                    
                    if let actual = record.actualPrice {
                        Text("Actual: $\(actual.formatted(.number.precision(.fractionLength(2))))")
                        let diff = record.predicted_price - actual
                        Text(diff >= 0 ? "Over by $\(abs(diff).formatted(.number.precision(.fractionLength(2))))" : "Under by $\(abs(diff).formatted(.number.precision(.fractionLength(2))))")
                            .foregroundStyle(diff >= 0 ? .orange : .blue)
                    } else {
                        Text("Pending")
                            .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                if let accuracy = record.accuracy {
                    Text("\(String(format: "%.1f", accuracy))%")
                        .font(.title3.bold())
                        .foregroundStyle(accuracy > 70 ? Color.successAccent : accuracy > 50 ? .orange : .red)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // MARK: Delete Button
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
extension Date {
    func toString(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
// MARK: - Helper Extensions (Add to PredictionRecord.swift)
extension PredictionRecord {
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: prediction_date)  // returns nil if invalid
    }
}
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
enum TimeRange: String, CaseIterable {
    case week7 = "Past 7 Days"
    case month30 = "Past 30 Days"
}
// MARK: - Preview

