import SwiftUI
import Charts
import PDFKit  // ← Add this
struct RecordDetailView: View {
    let model: PredictorModel
    let records: [PredictionRecord]
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
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
                        PriceChartSection(records: sortedRecords)
                            .padding(.horizontal)
                    }
                    
                    // MARK: Individual Records
                    IndividualRecordsSection(records: sortedRecords)
                        .padding(.horizontal)
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
                let chartView = PriceChartSection(records: sortedRecords)
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
private struct PriceChartSection: View {
    let records: [PredictionRecord]
    
    // MARK: - Dynamic Y-Axis Range
    private var priceRange: (min: Double, max: Double) {
        let prices = records.flatMap { [$0.predicted_price] + ($0.actualPrice.map { [$0] } ?? []) }
        guard let minPrice = prices.min(), let maxPrice = prices.max(), minPrice < maxPrice else {
            return (4000, 5000)
        }
        let buffer = 300.0
        return (minPrice - buffer, maxPrice + buffer)
    }
    
    // MARK: - Sample Points to Reduce Density
    private var pointRecords: [PredictionRecord] {
        let sorted = records.sorted { $0.parsedDate < $1.parsedDate }
        let step = max(1, sorted.count / 10)  // Max ~10 points
        return stride(from: 0, to: sorted.count, by: step).map { sorted[$0] }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Over Time")
                .font(.title3.bold())
                .padding(.horizontal)
            
            Chart {
                // Predicted Line (Gold)
                ForEach(sortedRecords) { record in
                    LineMark(
                        x: .value("Date", record.parsedDate),
                        y: .value("Predicted", record.predicted_price)
                    )
                    .foregroundStyle(Color.goldAccent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                
                // Actual Line (Blue)
                ForEach(sortedRecords.filter { $0.actualPrice != nil }) { record in
                    LineMark(
                        x: .value("Date", record.parsedDate),
                        y: .value("Actual", record.actualPrice!)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                
                // Predicted Points (Filled Gold Circle)
                ForEach(pointRecords) { record in
                    PointMark(
                        x: .value("Date", record.parsedDate),
                        y: .value("Predicted", record.predicted_price)
                    )
                    .foregroundStyle(Color.goldAccent)
                    .symbol(Circle())
                    .symbolSize(120)
                }
                
                // Actual Points (Blue Outline Circle)
                ForEach(pointRecords.filter { $0.actualPrice != nil }) { record in
                    PointMark(
                        x: .value("Date", record.parsedDate),
                        y: .value("Actual", record.actualPrice!)
                    )
                    .foregroundStyle(.clear)
                    .symbol(
                        Circle()
                            
                    )
                    .symbolSize(120)
                }
            }
            .frame(height: 340)
            .chartYScale(domain: priceRange.min...priceRange.max)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("$" + (value.as(Double.self)?.formatted(.number.precision(.fractionLength(0))) ?? ""))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                        .font(.caption)
                }
            }
            .chartLegend(position: .top, alignment: .center) {
                HStack(spacing: 20) {
                    LegendItem(color: Color.goldAccent, label: "Predicted")
                    LegendItem(color: .blue, label: "Actual")
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    private var sortedRecords: [PredictionRecord] {
        records.sorted { $0.parsedDate < $1.parsedDate }
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

// MARK: - Individual Records Section
private struct IndividualRecordsSection: View {
    let records: [PredictionRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Individual Predictions")
                .font(.title3.bold())
            
            ForEach(records) { record in
                PredictionRow(record: record)
            }
        }
    }
}

// MARK: - Single Row
private struct PredictionRow: View {
    let record: PredictionRecord
    
    var body: some View {
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
    var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: prediction_date) ?? Date()
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
// MARK: - Preview
#Preview {
    NavigationStack {
        RecordDetailView(
            model: PredictorModel(
                name: "My Gold Pro",
                description: "Custom model",
                apiURL: "",
                isAutoPredictEnabled: true
            ),
            records: []
        )
    }
}
