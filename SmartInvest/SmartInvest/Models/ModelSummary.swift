//
//  ModelSummary.swift
//  SmartInvest
//
//  Created by user on 29/12/2025.
//

import Foundation


/// Summary statistics for a predictor model's performance
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
        
        if pastRecords.isEmpty {
            overallAccuracy = "N/A"
            averageError = "N/A"
            bestPrediction = "N/A"
            worstPrediction = "N/A"
            winRate = "N/A"
        } else {
            let accuracies = pastRecords.compactMap { $0.accuracy }
            let avgAccuracy = accuracies.reduce(0, +) / Double(accuracies.count)
            overallAccuracy = String(format: "%.1f%%", avgAccuracy)
            
            let errors = pastRecords.map { abs($0.predicted_price - $0.actualPrice!) }
            let avgError = errors.reduce(0, +) / Double(errors.count)
            averageError = "$\(String(format: "%.2f", avgError))"
            
            if let best = pastRecords.max(by: { ($0.accuracy ?? 0) < ($1.accuracy ?? 0) }) {
                bestPrediction = "\(best.displayDate): \(String(format: "%.1f", best.accuracy ?? 0))%"
            } else {
                bestPrediction = "N/A"
            }
            
            if let worst = pastRecords.min(by: { ($0.accuracy ?? 0) < ($1.accuracy ?? 0) }) {
                worstPrediction = "\(worst.displayDate): \(String(format: "%.1f", worst.accuracy ?? 0))%"
            } else {
                worstPrediction = "N/A"
            }
            
            // Simple win rate: correct direction
            let directionCorrect = pastRecords.filter { record in
                guard let actual = record.actualPrice else { return false }
                let previous = pastRecords.first(where: { $0.prediction_date < record.prediction_date })
                let previousPrice = previous?.actualPrice ?? actual
                
                let predictedUp = record.predicted_price > previousPrice
                let actualUp = actual > previousPrice
                return predictedUp == actualUp
            }.count
            
            let winRatePercent = Double(directionCorrect) / Double(pastRecords.count) * 100
            winRate = String(format: "%.1f%%", winRatePercent)
        }
    }
}
