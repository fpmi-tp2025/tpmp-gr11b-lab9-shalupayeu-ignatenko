import Foundation

struct CardAccount: Identifiable, Codable, Equatable {
    let accountId: Int64
    let cardType: CardAccountType
    let overdraftLimit: Double?
    
    var id: Int64 { accountId }
    
    var displayOverdraft: String {
        guard let overdraft = overdraftLimit else {
            return "Недоступен"
        }
        if overdraft <= 0 {
            return "Недоступен"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = "₽"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: overdraft)) ?? "\(overdraft) ₽"
    }
    
    var hasOverdraft: Bool {
        guard let overdraft = overdraftLimit else { return false }
        return overdraft > 0
    }
}
