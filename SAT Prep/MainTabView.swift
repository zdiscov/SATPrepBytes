// MainTabView.swift

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            PracticeView()
                .tabItem { Label("Practice", systemImage: "pencil.circle.fill") }
            FullTestView()
                .tabItem { Label("Tests", systemImage: "doc.text.fill") }
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
    }
}
