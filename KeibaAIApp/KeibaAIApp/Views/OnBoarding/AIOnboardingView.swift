//
//  AIOnboardingView.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/10.
//
import SwiftUI

struct AIOnboardingView: View {
    // ViewmModelの変更をView側で検知するための部品
    @StateObject private var vm = AIOnboardingViewModel()
    // AI名
    @AppStorage("aiName") private var aiName: String = "あなた専用AI"
    // AIスタイル
    @AppStorage("aiStyleRaw") private var aiStyleRaw: String = AIStyle.pedigree.rawValue
    // ボーディングフラグ
    @AppStorage("onboardingDone") private var onboardingDone: Bool = false

    // 画面を閉じる際に使用する部品をEnvironmentから取得
    @Environment(\.dismiss) private var dismiss
    
    // true: 再診断で開かれた / false: 初回起動
    let isModal: Bool

    var body: some View {
        // 縦にUIを並べる
        VStack(spacing: 24) {
            Text(isModal ? "AIを作り直す" : "あなた専用AIを作成")
            // タイトルサイズで太字
                .font(.title).bold()
            // 質問の進捗バー(SwiftUIの公式部品) 青色にする
            ProgressView(value: vm.progress)
                .tint(.blue)
            // 質問文をViewModelにあるindexから引く
            Text(vm.questions[vm.index].text)
                .font(.title3).bold()
                // 中央揃え
                .multilineTextAlignment(.center)
                // 上余白
                .padding(.top, 8)

            // 横にUIを並べる
            HStack(spacing: 20) {
                Button("いいえ") { tapped(yes: false) }
                    // ボタンスタイル、枠付きボタン
                    .buttonStyle(.bordered)
                Button("はい") { tapped(yes: true) }
                    // ボタンスタイル、青い強調ボタン
                    .buttonStyle(.borderedProminent)
            }
            // フォントの大きさをタイトルサイズ3に
            .font(.title3)

            // 下に余白を作成
            Spacer()
        }
        // 余白
        .padding()
    }

    // 引数: はいをタップ時 true, いいえをタップ時 false
    private func tapped(yes: Bool) {
        // viewModelにはい、いいえを保存
        vm.answer(yes: yes)
        // 最後の質問ならAI決定
        if vm.isLast {
            // 最終判定
            let style = vm.finalizeStyle()
            aiStyleRaw = style.rawValue
            switch style {
            case .pedigree: aiName = "血統重視AI"
            case .time:     aiName = "タイム重視AI"
            case .jockey:   aiName = "騎手重視AI"
            case .profit:   aiName = "儲け重視AI"
            case .suitability: aiName =  "適性重視AI"
            }
            onboardingDone = true
            // AI再作成の場合は画面を閉じる
            if isModal {
                dismiss()
            }
        }
    }
}
#Preview("AITabView - Light Mode") {
    AITabView()
        .preferredColorScheme(.light)
}

#Preview("AITabView - Dark Mode") {
    AITabView()
        .preferredColorScheme(.dark)
}
