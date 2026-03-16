import SwiftUI

struct AITabView: View {
    @AppStorage("aiName") private var aiName: String = "あなた専用AI"
    @AppStorage("aiStyleRaw") private var aiStyleRaw: String = AIStyle.pedigree.rawValue
    @AppStorage("usedAmount") private var usedAmount: Int = 0
    @AppStorage("profit") private var profit: Int = 0
    @AppStorage("lastRaceTitle") private var lastRaceTitle: String = ""
    @AppStorage("lastRaceDateText") private var lastRaceDateText: String = ""
    @AppStorage("lastBetSummary") private var lastBetSummary: String = ""

    @State private var showManualChange = false
    @State private var showRebuild = false

    // 利益率の計算
    private var roi: Double {
        guard usedAmount > 0 else { return 0 }
        return (Double(profit) / Double(usedAmount)) * 100
    }

    // 予想内容のフォーマット整理
    private var lines: [String] {
        lastBetSummary
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // 安全エリアを無視
                .ignoresSafeArea()

                // スクロールView
                ScrollView {
                    // 上としたとのViewのスペース
                    VStack(spacing: 30) {
                        //　上の空白
                        Spacer(minLength: 16)
                        
                        // 下に記載されるHStackとのスペース
                        VStack(spacing: 18) {
                            Text(aiName)
                                .font(.title2).bold()
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)

                            Divider()

                            HStack(spacing: 12) {
                                StatCard(title: "使用金額", value: "\(usedAmount.formatted())円")
                                StatCard(title: "儲け", value: "\(profit.formatted())円")
                                StatCard(title: "回収率", value: String(format: "%.1f%%", roi))
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                        .padding(.horizontal, 20)

                        
                        VStack(spacing: 15) {
                            Button {
                                showManualChange = true
                            } label: {
                                Text("AIを変更する（手動）")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)

                            Button {
                                showRebuild = true
                            } label: {
                                Label("質問から再作成", systemImage: "questionmark.circle")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        .padding(.horizontal, 20)

                        if !lastRaceTitle.isEmpty {
                            VStack(alignment: .center, spacing: 10) {
                                // タイトル
                                Text("直近の予想")
                                    .font(.headline)
                                    .padding(5)

                                // レース名と日付
                                ZStack {
                                    Text(lastRaceTitle)
                                        .font(.subheadline)
                                        .bold()
                                    HStack {
                                        Spacer()
                                        Text(lastRaceDateText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Divider()

                                // Grid（買い目・金額）
                                VStack(alignment: .leading, spacing: 6) {
                                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                                        ForEach(lines, id: \.self) { line in
                                            let parts = line.split(separator: " ")
                                            GridRow {
                                                Text(parts.count > 0 ? String(parts[0]) : "")
                                                    .frame(width: 60, alignment: .leading)
                                                Text(parts.count > 1 ? String(parts[1]) : "")
                                                    .frame(width: 50, alignment: .leading)
                                                Text(parts.count > 2 ? String(parts[2]) : "")
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .monospacedDigit()
                                            }
                                            .font(.body)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.thinMaterial) // ← 直近予想カード全体
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            // 予想履歴ボタン
                            NavigationLink {
                                HistoryListView()
                            } label: {
                                Text("予想履歴一覧を見る")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            // AI変更シートへの遷移
            .sheet(isPresented: $showManualChange) {
                AIChangeSheet()
            }
            // AI質問シートへの遷移
            .fullScreenCover(isPresented: $showRebuild) {
                AIOnboardingView(isModal: true)
            }
        }
    }
}

#Preview("AI Tab View") {
    AITabView()
}
