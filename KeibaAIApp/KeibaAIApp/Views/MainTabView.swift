//
//  MainTabView.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        // タブビューでは最初に開いたタブが表示されるため、AIタブが初期タブとして設定される
        TabView {
            AITabView()
                // タブに表示される文字と画像を設定
                .tabItem { Label("AI", systemImage: "brain.head.profile") }
            PredictTabView()
                // タブに表示される文字と画像を設定
                .tabItem { Label("予想", systemImage: "trophy") }
        }
    }
}
