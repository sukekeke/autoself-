//
//  AIStyle.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

enum AIStyle: String, CaseIterable, Codable, Identifiable {
    case pedigree, time, jockey,profit,suitability
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .pedigree: return "血統重視"
        case .time:     return "タイム重視"
        case .jockey:   return "騎手重視"
        case .profit: return "儲け重視"
        case .suitability: return "適性重視"
        }
    }
}
