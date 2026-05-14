import Foundation
import Combine

class CurrencyViewModel: ObservableObject {
    @Published var rates: [CurrencyRate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: Date?
    @Published var displayLastUpdated: String = ""
    
    var formattedLastUpdated: String {
        guard let date = lastUpdated else {
            return "Обновите курсы"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .full
        
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .short
        timeFormatter.timeStyle = .short
        timeFormatter.locale = Locale(identifier: "ru_RU")
        
        return "Обновлено: \(relative)"
    }
    
    func loadRates() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fetchedRates = SQLiteManager.shared.getAllCurrencyRates()
            let lastUpdate = SQLiteManager.shared.getLastCurrencyUpdate()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.rates = fetchedRates
                self.lastUpdated = lastUpdate
                self.displayLastUpdated = self.formattedLastUpdated
                
                if fetchedRates.isEmpty {
                    self.errorMessage = "Курсы валют временно недоступны"
                }
            }
        }
    }
    
    func refreshRates() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Simulate fetching fresh rates with slight variations
            let newRates: [(String, Double)] = [
                ("USD", Double.random(in: 91.5...93.5)),
                ("EUR", Double.random(in: 99.0...101.5)),
                ("GBP", Double.random(in: 116.0...119.0)),
                ("JPY", Double.random(in: 0.60...0.63)),
                ("CNY", Double.random(in: 12.5...13.0)),
                ("CHF", Double.random(in: 103.0...106.0))
            ]
            
            for (currency, value) in newRates {
                SQLiteManager.shared.updateCurrencyRate(currency: currency, value: value)
            }
            
            let fetchedRates = SQLiteManager.shared.getAllCurrencyRates()
            let lastUpdate = SQLiteManager.shared.getLastCurrencyUpdate()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.rates = fetchedRates
                self.lastUpdated = lastUpdate
                self.displayLastUpdated = self.formattedLastUpdated
            }
        }
    }
}
