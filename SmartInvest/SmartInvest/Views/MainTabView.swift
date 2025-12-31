//
//  MainTabView.swift
//  SmartInvest
//
//  Created by user on 24/12/2025.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PredictHomeView()
                .tabItem {
                    Label("Predict", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            RecordView()
                .tabItem {
                    Label("Record", systemImage: "clock.arrow.circlepath")
                }
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "bubble.left.and.bubble.right")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color.primaryAccent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.backgroundSecondary, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
}
