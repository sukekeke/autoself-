//
//  PredictResultView.swift
//  KeibaAIApp
//
//  Created by suke on 2026/03/18.
//

import SwiftUI

struct PredictionResultView: View {
    let suggestions: [BetSuggestion]

    var body: some View {
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

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView

                    if suggestions.isEmpty {
                        emptyView
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                                suggestionCard(
                                    number: index + 1,
                                    text: suggestion.description
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("予想結果")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("買い目")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: 6) {
                Spacer()
                Text("\(suggestions.count)点")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 30)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("買い目がありません")
                .font(.headline)

            Text("条件を変えてもう一度予想してください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func suggestionCard(number: Int, text: String) -> some View {
        let parts = text.split(separator: " ").map(String.init)

        let horseText = parts.indices.contains(0) ? parts[0] : ""
        let typeText  = parts.indices.contains(1) ? parts[1] : ""
        let moneyText = parts.indices.contains(2) ? parts[2] : ""

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }

            HStack(spacing: 12) {
                Text(horseText)
                    .frame(width: 110, alignment: .leading) // ← 広めに

                Text(typeText)
                    .frame(width: 70, alignment: .leading)

                Text(moneyText)
                    .frame(width: 80, alignment: .trailing) // ← これが重要
                    .monospacedDigit()
            }
            .font(.title3)
            .fontWeight(.semibold)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}
