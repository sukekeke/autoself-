import Foundation

struct HttpKeibaAPI: KeibaAPI {
    
    private let baseURL = URL(string: "http://13.231.151.160:8080/api")!
    
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let f = DateFormatter()
        f.calendar = .init(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        d.dateDecodingStrategy = .formatted(f)
        return d
    }()
    
    // -------------------------
    // /races/upcoming
    // -------------------------
    func fetchUpcomingRaces() async throws -> [Race] {
        let url = baseURL.appendingPathComponent("races/upcoming")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try Self.decoder.decode([Race].self, from: data)
    }
    
    // -------------------------
    // /races/{id}
    // -------------------------
    func fetchRaceDetail(id: UUID) async throws -> Race {
        let url = baseURL.appendingPathComponent("races/\(id.uuidString)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try Self.decoder.decode(Race.self, from: data)
    }
    
    // -------------------------
    // POST /predict
    // -------------------------
    private struct PredictResponseDTO: Codable {
        let suggestions: [BetSuggestion]
    }
    
    func predict(
        raceId: UUID,
        stakeYen: Int,
        targetProfitYen: Int,
        aiStyle: String
    ) async throws -> [BetSuggestion] {
        
        let url = baseURL.appendingPathComponent("predict")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "raceId": raceId.uuidString,
            "stakeYen": stakeYen,
            "targetProfitYen": targetProfitYen,
            "aiStyle": aiStyle
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        // ★ ここを変更：DTOをやめて、配列として decode
        let suggestions = try Self.decoder.decode([BetSuggestion].self, from: data)
        return suggestions
    }
}
