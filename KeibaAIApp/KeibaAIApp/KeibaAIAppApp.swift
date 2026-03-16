//
//  KeibaAIAppApp.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/04.
//

import SwiftUI

@main
struct KeibaAIAppApp: App {
    // onboardingDonetというキーで端末に保存する
    @AppStorage("onboardingDone") private var onboardingDone: Bool = false

    var body: some Scene {
        // アプリのメインウィンドウを作る
        WindowGroup {
            if onboardingDone {
                // 既にAIがある → メインタブへ
                MainTabView()
            } else {
                // 初回起動 → 質問フロー　初回起動の場合はモーダル表示ではない
                AIOnboardingView(isModal: false)
            }
        }
    }
}
