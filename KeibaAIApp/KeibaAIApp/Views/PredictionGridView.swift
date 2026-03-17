//
//  PredictionGridView.swift
//  KeibaAIApp
//
//  Created by suke on 2026/03/17.
//
import SwiftUI

struct PredictionGridView: View {
    let lines: [String]
    var font: Font = .subheadline

    var body: some View {
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
                .font(font)
            }
        }
    }
}
