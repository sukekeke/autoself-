//
//  Race.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

struct Race: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let grade: String   // "G1"など
    let date: Date      // ← ここは Date のままでOK（方法1で頑張る）
}
