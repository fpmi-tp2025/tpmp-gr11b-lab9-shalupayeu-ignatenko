import Foundation

struct CurrencyRate: Identifiable, Codable, Equatable {
    let id: Int64
    let currency: String
    let value: Double
    let updatedAt: Date
    
    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var displayCurrency: String {
        switch currency.uppercased() {
        case "USD":
            return "🇺🇸 USD"
        case "EUR":
            return "🇪🇺 EUR"
        case "GBP":
            return "🇬🇧 GBP"
        case "JPY":
            return "🇯🇵 JPY"
        case "CNY":
            return "🇨🇳 CNY"
        case "CHF":
            return "🇨🇭 CHF"
        default:
            return currency.uppercased()
        }
    }
    
    var currencyName: String {
        switch currency.uppercased() {
        case "USD":
            return "Доллар США"
        case "EUR":
            return "Евро"
        case "GBP":
            return "Фунт стерлингов"
        case "JPY":
            return "Японская йена"
        case "CNY":
            return "Китайский юань"
        case "CHF":
            return "Швейцарский франк"
        default:
            return currency.uppercased()
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: updatedAt)
    }
}
