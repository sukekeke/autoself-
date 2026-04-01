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

    func formatAmount(_ value: Int) -> String {
        return value.formatted()
    }

    func formatProfit(_ value: Int) -> String {
        if value == 0 { return "±0" }
        return value > 0 ? "+\(value.formatted())" : value.formatted()
    }

    func formatProfitSmart(_ value: Int) -> String {
        if value == 0 { return "±0" }

        let sign = value > 0 ? "+" : ""
        let absValue = abs(value)

        if absValue >= 1_000_000 {
            let man = Double(absValue) / 1_000_000
            return "\(sign)\(Int(man))万"
        } else if absValue >= 10_000 {
            let man = Double(absValue) / 10_000
            return "\(sign)\(String(format: "%.1f", man))万"
        } else {
            return "\(sign)\(absValue.formatted())"
        }
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
                    // 上下とのViewのスペース
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

                                StatCard(
                                    title: "使用金額",
                                    value: "\(formatAmount(usedAmount))円"
                                )

                                StatCard(
                                    title: "儲け",
                                    value: "\(formatProfitSmart(profit))円",
                                    valueColor: profit > 0 ? .green : (profit < 0 ? .red : .secondary)
                                )

                                StatCard(
                                    title: "回収率",
                                    value: String(format: "%.1f%%", roi),
                                    valueColor: roi >= 100 ? .green : .red
                                )
                            }
                            .frame(maxWidth: .infinity)                        }
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
                                PredictionGridView(lines: lines, font: .body)
                                // 予想履歴ボタン
                                NavigationLink {
                                    HistoryListView()
                                } label: {
                                    Text("予想履歴一覧を見る")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                }
                            }
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
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
