//
//  BetSuggestion.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

struct BetSuggestion: Identifiable, Hashable, Codable {
    let id: UUID
    let pair: String      // 例: "7-15"
    let kind: String      // 例: "馬連"
    let amountYen: Int    // 例: 10000
    var description: String { "\(pair) \(kind) \(amountYen)円" }
    
    init(id: UUID = UUID(), pair: String, kind: String, amountYen: Int) {
            self.id = id
            self.pair = pair
            self.kind = kind
            self.amountYen = amountYen
        }
}
