//
//  AIOnboardingViewModel.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/10.
//
import SwiftUI

// 質問1つ分（どのスタイルにどれだけ寄与するかの重み付き）
struct AIQuestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let weights: [AIStyle: Int] // 例: [.pedigree: 2, .time: 0, .jockey: 0]
}

@MainActor
final class AIOnboardingViewModel: ObservableObject {
    @Published var index: Int = 0
    @Published var questions: [AIQuestion] = [
        AIQuestion(text: "血統を最も重視しますか？",         weights: [.pedigree: 2]),
        AIQuestion(text: "近走のタイムを強く重視しますか？", weights: [.time: 2]),
        AIQuestion(text: "騎手の実績・相性を重視しますか？",  weights: [.jockey: 2]),
        AIQuestion(text: "地道に努力することが嫌いですか？",       weights: [.profit: 2]),
        AIQuestion(text: "コースや距離など適性を重視しますか？", weights: [.suitability: 2]),

        AIQuestion(text: "距離適性よりも血統背景を重視する？", weights: [.pedigree: 1]),
        AIQuestion(text: "直近のラップや指数を重視する？",    weights: [.time: 1]),
        AIQuestion(text: "人気薄でも騎手買いをすることが多い？",weights: [.jockey: 1]),
        AIQuestion(text: "的中よりも儲けを狙うタイプですか？", weights: [.profit: 1]),
        AIQuestion(text: "天候や馬場状態を気にしますか？",   weights: [.suitability: 1]),
    ]

    private(set) var scores: [AIStyle: Int] = [
        .pedigree: 0,
        .time: 0,
        .jockey: 0,
        .profit: 0,
        .suitability: 0
    ]

    var isLast: Bool { index >= questions.count - 1 }
    var progress: Double { Double(index) / Double(max(questions.count, 1)) }

      func answer(yes: Bool) {
          let q = questions[index]
          if yes {
              for (style, w) in q.weights {
                  scores[style, default: 0] += w
              }
          }
          if !isLast { index += 1 }
      }

      // ③ ここの finalize() の中で「順位（order）」を使う
    func finalizeStyle() -> AIStyle {
            // 最もスコアが高いスタイルを採用
            let order: [AIStyle] = [.pedigree, .time, .jockey, .profit, .suitability]

            let best = scores.max { lhs, rhs in
                if lhs.value == rhs.value {
                    // 同点のときの優先順
                    return order.firstIndex(of: lhs.key)! > order.firstIndex(of: rhs.key)!
                } else {
                    return lhs.value < rhs.value
                }
            }?.key

            return best ?? .pedigree
        }
    
  }
