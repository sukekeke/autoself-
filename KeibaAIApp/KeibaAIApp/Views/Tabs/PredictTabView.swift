//
//  PredictTabView.swift
//  KeibaAIApp
//
//  Created by suke on 2026/03/18.
//

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

    private var style: AIStyle {
        AIStyle(rawValue: aiStyleRaw) ?? .pedigree
    }

    @StateObject private var vm = PredictViewModel(api: HttpKeibaAPI())

    @State private var profitText: String = ""
    @State private var usedAmountText: String = ""
    @State private var showResult = false
    @State private var isKeyboardVisible = false
    @State private var isLoading = false

    @FocusState private var focusedField: Field?

    enum Field {
        case stake
        case targetProfit
        case usedAmount
        case profit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Form {
                    raceSection
                    amountSection
                    resultSection
                }
                .scrollContentBackground(.hidden)
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()

                        ProgressView("AIが考え中...")
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isLoading)
            
            .safeAreaInset(edge: .bottom) {
                if !isKeyboardVisible {
                    bottomButtons
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") {
                        focusedField = nil
                    }
                }
            }
            .navigationDestination(isPresented: $showResult) {
                PredictionResultView(suggestions: vm.suggestions)
            }
            .task {
                profitText = String(profit)
                usedAmountText = String(usedAmount)
                await vm.loadRaces()
            }
            .onAppear {
                startKeyboardObservers()
            }
            .onDisappear {
                stopKeyboardObservers()
            }
            .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
        }
    }

    // MARK: - Sections

    private var raceSection: some View {
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
    }

    private var amountSection: some View {
        Section("掛け金／目標利益") {
            Stepper(
                value: $vm.stakeYen,
                in: 1_000...200_000,
                step: 1_000
            ) {
                HStack {
                    Text("掛け金")
                    Spacer()
                    TextField("0", value: $vm.stakeYen, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($focusedField, equals: .stake)
                        .onChange(of: vm.stakeYen) { _, newValue in
                            if newValue < 0 { vm.stakeYen = 0 }
                            if newValue > 200_000 { vm.stakeYen = 200_000 }
                        }
                }
            }

            Stepper(
                value: $vm.targetProfitYen,
                in: 1_000...300_000,
                step: 1_000
            ) {
                HStack {
                    Text("目標回収金額")
                    Spacer()
                    TextField("0", value: $vm.targetProfitYen, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($focusedField, equals: .targetProfit)
                        .onChange(of: vm.targetProfitYen) { _, newValue in
                            if newValue < 0 { vm.targetProfitYen = 0 }
                            if newValue > 300_000 { vm.targetProfitYen = 300_000 }
                        }
                }
            }

            let req = max(
                1.0,
                Double(vm.stakeYen + vm.targetProfitYen) / Double(max(vm.stakeYen, 1))
            )

            HStack {
                Text("必要リターン")
                Spacer()
                Text(String(format: "%.2fx", req))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var resultSection: some View {
        Section("成績(手動計算)") {
            HStack {
                Text("使用金額累計")
                Spacer()
                TextField("0", text: $usedAmountText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 140)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .focused($focusedField, equals: .usedAmount)
                    .onChange(of: usedAmountText) { _, newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        let limited = String(digitsOnly.prefix(11))

                        if limited != newValue {
                            usedAmountText = limited
                        }

                        usedAmount = Int(limited) ?? 0
                    }
            }

            HStack {
                Text("儲け累計")
                Spacer()
                TextField("0", text: $profitText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 140)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .focused($focusedField, equals: .profit)
                    .onChange(of: profitText) { _, newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        let limited = String(digitsOnly.prefix(11))

                        if limited != newValue {
                            profitText = limited
                        }

                        profit = Int(limited) ?? 0
                    }
            }

            Stepper(
                value: $profit,
                in: -999_999_999...999_999_999,
                step: 1_000
            ) {
                Text("±1,000円 調整")
            }
            .onChange(of: profit) { _, newValue in
                profitText = String(newValue)
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                vm.stakeYen = 0
                vm.targetProfitYen = 0
                vm.suggestions = []
            } label: {
                Text("金額をリセット")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)

            Button {
                Task {
                    guard let race = vm.selectedRace else { return }

                    isLoading = true
                    await vm.predict(style: style)
                    isLoading = false

                    usedAmount += vm.stakeYen
                    usedAmountText = String(usedAmount)

                    lastRaceTitle = race.name
                    lastRaceDateText = dateString(race.date)
                    lastBetSummary = vm.suggestions
                        .map { $0.description }
                        .joined(separator: " / ")

                    var history = loadHistory()
                    let newItem = BetHistory(
                        date: Date(),
                        raceName: race.name,
                        summary: lastBetSummary,
                        result: .pending
                    )
                    history.insert(newItem, at: 0)
                    saveHistory(history)

                    showResult = true
                }
            } label: {
                Label("予想する", systemImage: "lightbulb.max")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.selectedRace == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Keyboard Observers

    private func startKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = true
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = false
        }
    }

    private func stopKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Helpers

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(E)"
        return f.string(from: d)
    }

    private func loadHistory() -> [BetHistory] {
        guard
            !betHistoryJSON.isEmpty,
            let list = try? JSONDecoder().decode([BetHistory].self, from: betHistoryJSON)
        else {
            return []
        }
        return list
    }

    private func saveHistory(_ list: [BetHistory]) {
        if let data = try? JSONEncoder().encode(list) {
            betHistoryJSON = data
        }
    }
}
