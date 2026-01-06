//
//  ContentView.swift
//  Akanuke
//
//  Created by K on 2026/01/06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var records = RecordsStore()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
        .environmentObject(records)
    }
}

#Preview {
    ContentView()
}
