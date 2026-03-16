// PredictTabView.swift
import SwiftUI

struct PredictTabView: View {
    @AppStorage("aiName") private var aiName: String = ""
    @AppStorage("aiStyleRaw") private var aiStyleRaw: String = AIStyle.pedigree.rawValue
    @AppStorage("usedAmount") private var usedAmount: Int = 0
    @AppStorage("profit") private var profit: Int = 0
    @AppStorage("lastRaceTitle") private var lastRaceTitle: String = ""
    @AppStorage("lastRaceDateText") private var lastRaceDateText: String = ""
    @AppStorage("lastBetSummary") private var lastBetSummary: String = ""
    @AppStorage("betHistoryJSON") private var betHistoryJSON: Data = Data()

    private var style: AIStyle { AIStyle(rawValue: aiStyleRaw) ?? .pedigree }

    @StateObject private var vm = PredictViewModel(api: HttpKeibaAPI())
    @State private var profitText: String = ""

    // TextField 用
    @FocusState private var focusedField: Field?
    enum Field {
        case stake
        case targetProfit
        case profit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {

                    // ▼ 入力部分（Form）
                    Form {
                        // レース選択
                        Section("レース（直近1週間のG1）") {
                            if vm.g1NextWeek.isEmpty {
                                Text("直近1週間にG1はありません")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("レースを選択", selection: $vm.selectedRace) {
                                    ForEach(vm.g1NextWeek) { race in
                                        Text("\(race.name)  \(dateString(race.date))")
                                            .tag(Optional(race))
                                    }
                                }
                            }
                        }
                        
                        Section("掛け金／目標利益") {
                            // 掛け金（合計）
                            Stepper(value: $vm.stakeYen,
                                     in: 1_000...200_000,
                                     step: 1_000) {
                                 HStack {
                                     Text("掛け金")
                                     Spacer()
                                     TextField("0", value: $vm.stakeYen, format: .number)
                                         .keyboardType(.numberPad)
                                         .multilineTextAlignment(.trailing)
                                         .frame(width: 100)
                                         .focused($focusedField, equals: .stake)
                                         .onChange(of: vm.stakeYen) { oldValue, newValue in
                                             // 負の値禁止 & 最大値制限
                                             if newValue < 0 { vm.stakeYen = 0 }
                                             if newValue > 200_000 { vm.stakeYen = 200_000 }
                                         }
                                 }
                             }

                            // 儲けたい金額
                            Stepper(value: $vm.targetProfitYen,
                                    in: 1_000...300_000,
                                    step: 1_000) {
                                HStack {
                                    Text("目標回収金額")
                                    Spacer()
                                    TextField("0", value: $vm.targetProfitYen, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                        .focused($focusedField, equals: .targetProfit)
                                        .onChange(of: vm.targetProfitYen) { oldValue, newValue in
                                            if newValue < 0 { vm.targetProfitYen = 0 }
                                            if newValue > 300_000 { vm.targetProfitYen = 300_000 }
                                        }
                                }
                            }

                            let req = max(
                                1.0,
                                Double(vm.stakeYen + vm.targetProfitYen)
                                / Double(max(vm.stakeYen, 1))
                            )

                            HStack {
                                Text("必要リターン")
                                Spacer()
                                Text(String(format: "%.2fx", req))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // 儲け累計（手動更新）
                        Section("成績") {
                            HStack {
                                Text("儲け累計")
                                Spacer()
                                TextField("0", text: $profitText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 140)          // 少し広めに
                                    .lineLimit(1)               // 1行だけ
                                    .minimumScaleFactor(0.6)    // 収まらないときは 60% まで縮小
                                    .focused($focusedField, equals: .profit)
                                    .onChange(of: profitText) { oldValue, newValue in
                                        // 1) 数字だけ残す
                                        let digitsOnly = newValue.filter { $0.isNumber }

                                        // 2) 最大 9 桁に制限（例：999,999,999 まで）
                                        let limited = String(digitsOnly.prefix(9))

                                        if limited != newValue {
                                            profitText = limited
                                        }

                                        // 3) Int に変換して AppStorage に反映
                                        profit = Int(limited) ?? 0
                                    }
                            }

                            Stepper(value: $profit,
                                    in: -999_999_999...999_999_999,
                                    step: 1_000) {
                                Text("±1,000円 調整")
                            }
                            .onChange(of: profit) { _, newValue in
                                profitText = String(newValue)
                            }
                        }
                        .onAppear {
                            // 画面表示時に TextField と profit を同期
                            profitText = String(profit)
                        }
                    }
                    .scrollContentBackground(.hidden)

                    // ▼ フォームの下のボタン & 買い目カード
                    VStack(spacing: 16) {

                        // 金額リセットボタン
                        Button {
                            vm.stakeYen = 0
                            vm.targetProfitYen = 0
                            vm.suggestions = []
                        } label: {
                            Text("金額をリセット")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)

                        // 予想するボタン
                        Button {
                            Task {
                                guard let race = vm.selectedRace else { return }

                                // サーバーに予想リクエスト
                                await vm.predict(style: style)

                                usedAmount += vm.stakeYen

                                // 直近の予想（AIタブ表示用）
                                lastRaceTitle = race.name
                                lastRaceDateText = dateString(race.date)
                                lastBetSummary = vm.suggestions
                                    .map { $0.description }
                                    .joined(separator: " / ")

                                // 履歴保存
                                var history = loadHistory()
                                let newItem = BetHistory(
                                    date: Date(),
                                    raceName: race.name,
                                    summary: lastBetSummary,
                                    result: .pending
                                )
                                history.insert(newItem, at: 0)
                                saveHistory(history)
                            }
                        } label: {
                            Label("予想する", systemImage: "lightbulb.max")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.selectedRace == nil)

                        // 買い目カード
                        if !vm.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("買い目（\(vm.suggestions.count)点）")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(vm.suggestions) { s in
                                        Text(s.description)
                                            .font(.title2)          // ← ★ フォント大きく
                                            .fontWeight(.semibold)  // ← ★ 見やすく太字
                                            .frame(maxWidth: .infinity, alignment: .leading) // ← 左寄せ & 幅いっぱい
                                            .padding(.vertical, 4)  // ← 行間を広げる
                                    }
                                }

                                Text("※オッズ未考慮の配分。的中後は「儲け」を手動更新してください。")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            Spacer(minLength: 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            // キーボード上に「閉じる」ボタン
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") {
                        focusedField = nil
                    }
                }
            }
            // 画面表示時に1回だけレース一覧取得
            .task {
                await vm.loadRaces()
            }
        }
    }

    // MARK: - 日付表示

    func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(E)"
        return f.string(from: d)
    }

    // MARK: - 履歴保存・読み出し

    func loadHistory() -> [BetHistory] {
        guard !betHistoryJSON.isEmpty,
              let list = try? JSONDecoder().decode([BetHistory].self,
                                                   from: betHistoryJSON)
        else {
            return []
        }
        return list
    }

    func saveHistory(_ list: [BetHistory]) {
        if let data = try? JSONEncoder().encode(list) {
            betHistoryJSON = data
        }
    }
}
