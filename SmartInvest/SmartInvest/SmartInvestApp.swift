//
//  SmartInvestApp.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import SwiftUI

@main
struct SmartInvestApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
            // Use the instance's locale
                .environment(\.locale, languageManager.locale)
                           
                .environmentObject(languageManager)
        }
    }
}
