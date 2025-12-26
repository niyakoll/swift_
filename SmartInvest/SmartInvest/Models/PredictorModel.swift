import Foundation
import SwiftUI
/// Represents a single AI predictor model profile
/// Used for both the built-in default model and user-created custom models
struct PredictorModel: Identifiable, Codable, Equatable {
    // MARK: - Properties
    /// Unique identifier – required for SwiftUI ForEach
    let id = UUID()
    
    /// Display name shown in cards and detail view
    var name: String
    
    /// Optional description shown below the name
    var description: String
    
    /// The Flask API endpoint the app will call for predictions
    var apiURL: String
    
    /// Whether daily auto-prediction is enabled
    var isAutoPredictEnabled: Bool
    
    // MARK: - Initializer
    /// Convenience initializer with default values
    init(
        name: String,
        description: String = "",
        apiURL: String,
        isAutoPredictEnabled: Bool = true
    ) {
        self.name = name
        self.description = description
        self.apiURL = apiURL
        self.isAutoPredictEnabled = isAutoPredictEnabled
    }
    
    // MARK: - Equatable (for future array comparisons)
    static func == (lhs: PredictorModel, rhs: PredictorModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Helper (Optional – useful for previews)
#if DEBUG
extension PredictorModel {
    static var previewDefault: PredictorModel {
        PredictorModel(
            name: "SmartInvest Default",
            description: "Official gold price predictor powered by advanced RNN model",
            apiURL: "https://your-flask-server.com/default-predict",
            isAutoPredictEnabled: true
        )
    }
    
    static var previewUser: PredictorModel {
        PredictorModel(
            name: "My Gold Pro",
            description: "Custom high-accuracy model with volatility adjustments",
            apiURL: "https://my-server.com/predict",
            isAutoPredictEnabled: false
        )
    }
}
#endif
