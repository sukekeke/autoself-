//
//  PredictViewModel.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

@MainActor
final class PredictViewModel: ObservableObject {
    @Published var allRaces: [Race] = []
    @Published var g1NextWeek: [Race] = []
    @Published var selectedRace: Race?
    @Published var stakeYen: Int = 0           // 掛け金（合計）
    @Published var targetProfitYen: Int = 0    // 目標利益
    @Published var suggestions: [BetSuggestion] = []

    private let api: KeibaAPI   // ★ 追加：APIを持たせる

        // ★ イニシャライザを追加
        init(api: KeibaAPI) {
            self.api = api
        }
    
    // ★ サーバーからレース一覧を取ってきてフィルタする
    func loadRaces() async {
        do {
            let races = try await api.fetchUpcomingRaces()
            self.allRaces = races
            filterNextWeekG1()          // ← ここでG1抽出
        } catch {
            print("loadRaces error:", error)
        }
    }

    func filterNextWeekG1() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        g1NextWeek = allRaces.filter { $0.grade == "G1" && ($0.date >= start && $0.date < end) }
        selectedRace = g1NextWeek.first
    }

    /// 買い目生成ロジック：
    ///  - スタイル別の基準ペアから上位を採用
    ///  - 目標利益 ÷ 掛け金 で必要リターン感を推定し、点数（配分数）を1〜5で調整
    ///  - 掛け金は点数で割って配分（端数は先頭に寄せる）
    func predict(style: AIStyle) async {
            guard let race = selectedRace else { return }

        do {
                let styleRaw = style.rawValue
                let result = try await api.predict(
                    raceId: race.id,
                    stakeYen: stakeYen,
                    targetProfitYen: targetProfitYen,
                    aiStyle: styleRaw
                )
                withAnimation(.spring()) {
                    self.suggestions = result
                }
            } catch {
                print("predict error:", error)
            }
        }
    }
