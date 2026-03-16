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
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).monospacedDigit().lineLimit(1)            // ★ 1行から折り返さない
                .minimumScaleFactor(0.7) // ★ 収まらないときは少し縮める
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}
