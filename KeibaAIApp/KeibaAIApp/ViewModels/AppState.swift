//
//  AppState.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

// どのタブを開いているか
enum AppTab: Hashable { case ai, predict }

// 依存を差し替えたい場合のAPIプロトコル（任意）
// 実装例: struct MockKeibaAPI: KeibaAPI { ... }
protocol KeibaAPI {
    func fetchUpcomingRaces() async throws -> [Race]
    func fetchRaceDetail(id: UUID) async throws -> Race
    
    func predict(
            raceId: UUID,
            stakeYen: Int,
            targetProfitYen: Int,
            aiStyle: String
        ) async throws -> [BetSuggestion]
}

@MainActor
final class AppState: ObservableObject {

    // MARK: - 永続化（@AppStorage）: アプリ再起動後も残したい値
    @AppStorage("aiName")      var aiName: String = "血統重視AI"
    @AppStorage("aiStyleRaw")  var aiStyleRaw: String = AIStyle.pedigree.rawValue
    @AppStorage("usedAmount")  var usedAmount: Int = 0     // 使用金額(総投資)
    @AppStorage("profit")      var profit: Int = 0         // 純利益(累計)
    @AppStorage("onboardingDone") var onboardingDone: Bool = false // 初回AI作成済みフラグ

    // MARK: - 画面制御（非永続）
    @Published var selectedTab: AppTab = .ai
    @Published var navPath = NavigationPath()               // 必要ならナビゲーション用
    @Published var isPresentingAIChange = false            // AI変更シート表示
    @Published var toastMessage: String? = nil             // トースト/エラーバナー

    // MARK: - 依存（DI）
    let api: KeibaAPI

    init(api: KeibaAPI /* = MockKeibaAPI() */) {
        self.api = api
        // 初回起動時はAI作成フローへ誘導したい場合:
        if !onboardingDone { selectedTab = .ai }
    }

    // MARK: - 計算プロパティ
    var aiStyle: AIStyle {
        get { AIStyle(rawValue: aiStyleRaw) ?? .pedigree }
        set { aiStyleRaw = newValue.rawValue }
    }

    var roi: Double {
        guard usedAmount > 0 else { return 0 }
        return (Double(profit) / Double(usedAmount)) * 100.0
    }

    // MARK: - グローバル操作（Actions）

    /// 初回セットアップを完了にする（AI作成完了時に呼ぶ）
    func completeOnboarding() {
        onboardingDone = true
        selectedTab = .ai            // 既定タブへ
    }

    /// AIの名前／スタイルを更新（AI変更保存ボタンで呼ぶ）
    func updateAI(name: String?, style: AIStyle?) {
        if let n = name, !n.trimmingCharacters(in: .whitespaces).isEmpty {
            aiName = n
        }
        if let s = style { aiStyle = s }
        toast("AIを更新しました")
    }

    /// 掛け金を「使用金額」に積み上げ（予想実行時に呼ぶ）
    func addStake(_ yen: Int) {
        guard yen > 0 else { return }
        usedAmount += yen
    }

    /// 的中結果を反映（＋なら利益、－なら損失）
    func addProfit(_ yen: Int) {
        profit += yen
    }

    /// 成績リセット（確認ダイアログのあとで呼ぶ想定）
    func resetStats() {
        usedAmount = 0
        profit = 0
        toast("成績をリセットしました")
    }

    /// 共通トースト表示
    func toast(_ message: String) {
        toastMessage = message
        // 必要なら一定時間で自動クリアする処理を足す
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if toastMessage == message { toastMessage = nil }
        }
    }

    /// 共通エラーハンドリング
    func report(_ error: Error) {
        toast("エラー: \(error.localizedDescription)")
    }
}
