import Foundation

/// 予想結果
enum BetResult: String, Codable, CaseIterable, Identifiable {
    case pending   // まだ判定してない
    case hit       // 的中
    case miss      // ハズレ

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "判定前"
        case .hit:     return "的中"
        case .miss:    return "ハズレ"
        }
    }
}

struct BetHistory: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let raceName: String
    let summary: String
    var result: BetResult   // ★ 追加

    init(id: UUID = UUID(),
         date: Date,
         raceName: String,
         summary: String,
         result: BetResult = .pending) {   // 新規は「判定前」
        self.id = id
        self.date = date
        self.raceName = raceName
        self.summary = summary
        self.result = result
    }
}
