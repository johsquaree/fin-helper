//
//  ContentView.swift
//  FinHelper
//
//  Created by Sühan Düşünceli on 13.04.2025.
//

import SwiftUI

struct ContentView: View {
    @Binding var pendingInviteCode: String?
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab = 0
    @State private var showingJoinGroup = false
    @AppStorage("darkMode") private var darkMode = false

    init(pendingInviteCode: Binding<String?> = .constant(nil)) {
        _pendingInviteCode = pendingInviteCode
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Cüzdan sekmesi
            WalletView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Cüzdan")
                }
                .tag(0)
            
            // Gruplar sekmesi
            GroupsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Gruplar")
                }
                .tag(1)
            
            // İstatistikler sekmesi
            StatsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("İstatistikler")
                }
                .tag(2)
            
            // Profil sekmesi
            ProfileView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .preferredColorScheme(darkMode ? .dark : .light)
        .onAppear {
            updateAppearance(isDark: darkMode)
            Task { await viewModel.syncExpensesFromBackend() }
        }
        .onChange(of: darkMode) { _, newValue in
            updateAppearance(isDark: newValue)
        }
        .onChange(of: pendingInviteCode) { _, code in
            if code != nil {
                selectedTab = 1
                showingJoinGroup = true
            }
        }
        .sheet(isPresented: $showingJoinGroup, onDismiss: { pendingInviteCode = nil }) {
            JoinGroupView(viewModel: viewModel, initialCode: pendingInviteCode ?? "")
        }
    }
    
    private func updateAppearance(isDark: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
        }
    }
}

#Preview {
    ContentView()
}
