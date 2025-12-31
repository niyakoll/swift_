import Foundation

/// Represents one prediction made by a specific AI model
struct PredictionRecord: Identifiable, Codable {
    // MARK: - Supabase Columns (optional because they come from server)
    let id: Int64?
    let created_at: Date?
    let user_id: UUID
    let user_email: String?
    
    // MARK: - Prediction Data
    let model_id: UUID
    let model_name: String
    let prediction_date: String  // "yyyy-MM-dd"
    let predicted_price: Double
    let optimism_bias: Double
    
    // MARK: - Local Helper (filled later)
    var actualPrice: Double? = nil
    
    // MARK: - Identifiable (use Supabase ID if available, else UUID)
    var identifiableID: String {
        if let supabaseID = id {
            return "supabase-\(supabaseID)"
        } else {
            return UUID().uuidString
        }
    }
    
    // MARK: - Required for SwiftUI ForEach
    //var id: String { identifiableID }
    
    // MARK: - Computed Properties
    var isFuture: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let predDate = formatter.date(from: prediction_date) else { return true }
        let today = Calendar.current.startOfDay(for: Date())
        let predDay = Calendar.current.startOfDay(for: predDate)
        return predDay >= today
    }
    
    var accuracy: Double? {
        guard let actual = actualPrice, actual > 0 else { return nil }
        let diff = abs(predicted_price - actual)
        let accuracy = 100 - (diff / actual * 100)
        return max(0, min(100, accuracy))
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        if let date = DateFormatter.yyyyMMdd.date(from: prediction_date) {
            return formatter.string(from: date)
        }
        return prediction_date
    }
    
    var createdDateDisplay: String {
        guard let created = created_at else { return "Just now" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: created)
    }
}

// MARK: - Reusable Date Formatter
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
