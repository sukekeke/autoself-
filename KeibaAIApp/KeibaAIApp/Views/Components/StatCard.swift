//
//  StatCard.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .foregroundColor(valueColor) // ←ここ追加
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
