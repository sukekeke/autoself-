// HistoryListView.swift
import SwiftUI

struct HistoryListView: View {
    // PredictTabView と同じキーで保存された JSON を読む
    @AppStorage("betHistoryJSON") private var betHistoryJSON: Data = Data()

    @State private var list: [BetHistory] = []
    
    // どのタブが選ばれているか
    @State private var filter: HistoryFilter = .all
    
    enum HistoryFilter: String, CaseIterable, Identifiable {
        case all    = "すべて"
        case hit    = "的中"
        case miss   = "ハズレ"

        var id: String { rawValue }

        var title: String { rawValue }
    }

    var body: some View {
            VStack {
                //上部タブ
                Picker("フィルタ", selection: $filter) {
                    ForEach(HistoryFilter.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                // 一覧本体
                List {
                    if filteredHistory.isEmpty {
                        Text("まだ予想履歴がありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredHistory) { item in
                            row(for: item)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("予想履歴")
            .onAppear {
                list = load()
            }
        }

        private var filteredHistory: [BetHistory] {
            switch filter {
            case .all:
                return list
            case .hit:
                return list.filter { $0.result == .hit }
            case .miss:
                return list.filter { $0.result == .miss }
            }
        }

        // 複数のViewをまとめて返せる
        @ViewBuilder
        private func row(for item: BetHistory) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                ZStack {
                    // 中央：レース名
                    Text(item.raceName)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    // 左：日付
                    HStack {
                        Text(dateString(item.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }

                    // 右：バッジ
                    HStack {
                        Spacer()

                        Text(item.result.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(resultColor(item.result).opacity(0.15))
                            .foregroundColor(resultColor(item.result))
                            .clipShape(Capsule())
                    }
                }

                // 2行目以降：買い目を「/」で区切って1行ずつ
                        let lines = item.summary
                            .split(separator: "/")
                            .map { $0.trimmingCharacters(in: .whitespaces) }

                PredictionGridView(lines: lines)
            }
            .padding(.vertical, 6)
            .swipeActions(edge: .trailing) {
                Button("的中") {
                    update(item, result: .hit)
                }
                .tint(.green)

                Button("ハズレ") {
                    update(item, result: .miss)
                }
                .tint(.red)
            }
        }

        private func resultColor(_ r: BetResult) -> Color {
            switch r {
            case .hit:   return .green
            case .miss:  return .red
            case .pending: return .gray
            }
        }


        private func load() -> [BetHistory] {
            guard !betHistoryJSON.isEmpty,
                  let list = try? JSONDecoder().decode([BetHistory].self,
                                                       from: betHistoryJSON)
            else { return [] }
            return list
        }

        private func save(_ list: [BetHistory]) {
            if let data = try? JSONEncoder().encode(list) {
                betHistoryJSON = data
            }
        }

        private func update(_ item: BetHistory, result: BetResult) {
            guard let idx = list.firstIndex(where: { $0.id == item.id }) else { return }
            list[idx].result = result
            save(list)
        }

        private func dateString(_ d: Date) -> String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "M/d(E)"
            return f.string(from: d)
        }
    }
