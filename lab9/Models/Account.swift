import Foundation

enum AccountType: String, CaseIterable, Identifiable, Codable {
    case current = "current"
    case savings = "savings"
    case credit = "credit"
    case card = "card"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .current:
            return "Текущий"
        case .savings:
            return "Сберегательный"
        case .credit:
            return "Кредитный"
        case .card:
            return "Карт-счет"
        }
    }
    
    var iconName: String {
        switch self {
        case .current:
            return "doc.text"
        case .savings:
            return "piggy.bank"
        case .credit:
            return "creditcard"
        case .card:
            return "creditcard.fill"
        }
    }
    
    var color: String {
        switch self {
        case .current:
            return "blue"
        case .savings:
            return "green"
        case .credit:
            return "orange"
        case .card:
            return "purple"
        }
    }
}

enum CardAccountType: String, CaseIterable, Identifiable, Codable {
    case salary = "salary"
    case savings = "savings"
    case credit = "credit"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .salary:
            return "Зарплатный"
        case .savings:
            return "Сберегательный"
        case .credit:
            return "Кредитный"
        }
    }
}

struct Account: Identifiable, Codable, Equatable {
    let id: Int64
    let userId: Int64
    let name: String
    let balance: Double
    let type: AccountType
    let isActive: Bool
    let isBlocked: Bool
    let isClosed: Bool
    
    var displayBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = "₽"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: balance)) ?? "\(balance) ₽"
    }
    
    var statusText: String {
        if isBlocked {
            return "Заблокирован"
        } else if isActive {
            return "Активен"
        } else {
            return "Неактивен"
        }
    }
    
    var statusColor: String {
        if isBlocked {
            return "red"
        } else if isActive {
            return "green"
        } else {
            return "gray"
        }
    }
}
