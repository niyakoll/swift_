//
//  SettingView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("user@example.com")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Section {
                    Button("Log Out") {
                        // Later: Supabase sign out
                        // For now: just print
                        print("Logged out")
                    }
                    .foregroundStyle(Color.destructiveAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
