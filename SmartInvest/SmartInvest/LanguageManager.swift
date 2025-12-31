import Foundation
import SwiftUI
internal import Combine

// Singleton — one shared instance for the whole app
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // MARK: - User's language choice (saved automatically)
    // This is the value we read/write from UserDefaults
    @AppStorage("appLanguage") private var storedLanguage: String = "en"
    
    // MARK: - Published property — this triggers UI updates
    // When this changes, SwiftUI redraws any view using .environment(\.locale, ...)
    @Published var selectedLanguage: String = "en" {
        didSet {
            // Sync the @AppStorage whenever selectedLanguage changes
            storedLanguage = selectedLanguage
        }
    }
    
    private init() {
        // On launch, sync the published value with saved one
        self.selectedLanguage = storedLanguage
    }
    
    // MARK: - Computed Locale for SwiftUI
    var locale: Locale {
        Locale(identifier: selectedLanguage)
    }
}
