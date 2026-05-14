import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: Int64
    let login: String
    let password: String
}
