import Foundation

// Summary statistics for a predictor model's performance
struct ModelSummary {
    let totalPredictions: Int
    let dateRange: String
    let overallAccuracy: String
    let averageError: String
    let bestPrediction: String
    let worstPrediction: String
    let winRate: String
    let pendingPredictions: Int
    
    init(from records: [PredictionRecord]) {
        totalPredictions = records.count
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if let first = records.min(by: { $0.prediction_date < $1.prediction_date }),
           let last = records.max(by: { $0.prediction_date < $1.prediction_date }) {
            let firstDate = formatter.date(from: first.prediction_date) ?? Date()
            let lastDate = formatter.date(from: last.prediction_date) ?? Date()
            dateRange = "\(formatter.string(from: firstDate)) – \(formatter.string(from: lastDate))"
        } else {
            dateRange = "No predictions"
        }
        
        let pastRecords = records.filter { !$0.isFuture }
        pendingPredictions = records.filter { $0.isFuture }.count
        
        // Only use records with actual price
        let validRecords = pastRecords.filter { $0.actualPrice != nil }
        //safe fall-back, if empty, value = nil
        if validRecords.isEmpty {
            overallAccuracy = "N/A"
            averageError = "N/A"
            bestPrediction = "N/A"
            worstPrediction = "N/A"
            winRate = "N/A"
        } else {
            // Accuracy
            let accuracies = validRecords.map { record in
                let actual = record.actualPrice!  // Safe: we filtered nil above
                let diff = abs(record.predicted_price - actual)
                let accuracy = 100 - (diff / actual * 100)
                return max(0, min(100, accuracy))
            }
            let avgAccuracy = accuracies.reduce(0, +) / Double(accuracies.count)
            overallAccuracy = String(format: "%.1f%%", avgAccuracy)
            
            // Average Error
            let errors = validRecords.map { record in
                abs(record.predicted_price - record.actualPrice!)
            }
            let avgError = errors.reduce(0, +) / Double(errors.count)
            averageError = "$\(String(format: "%.2f", avgError))"
            
            // Best Prediction
            if let best = validRecords.max(by: { ($0.accuracy ?? 0) < ($1.accuracy ?? 0) }) {
                bestPrediction = "\(best.displayDate): \(String(format: "%.1f", best.accuracy ?? 0))%"
            } else {
                bestPrediction = "N/A"
            }
            
            // Worst Prediction
            if let worst = validRecords.min(by: { ($0.accuracy ?? 0) < ($1.accuracy ?? 0) }) {
                worstPrediction = "\(worst.displayDate): \(String(format: "%.1f", worst.accuracy ?? 0))%"
            } else {
                worstPrediction = "N/A"
            }
            
            // Win Rate (correct direction)
            let directionCorrect = validRecords.filter { record in
                let previous = validRecords.first(where: { $0.prediction_date < record.prediction_date })
                let previousPrice = previous?.actualPrice ?? record.actualPrice!
                
                let predictedUp = record.predicted_price > previousPrice
                let actualUp = record.actualPrice! > previousPrice
                return predictedUp == actualUp
            }.count
            
            let winRatePercent = Double(directionCorrect) / Double(validRecords.count) * 100
            winRate = String(format: "%.1f%%", winRatePercent)
        }
    }
}
