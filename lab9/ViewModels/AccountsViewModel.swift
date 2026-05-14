import Foundation
import Combine

class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var filteredAccounts: [Account] = []
    @Published var selectedAccount: Account?
    @Published var cardDetails: CardAccount?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedFilter: AccountType? = nil
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    var activeCount: Int {
        accounts.filter { $0.isActive && !$0.isBlocked }.count
    }
    
    var blockedCount: Int {
        accounts.filter { $0.isBlocked }.count
    }
    
    var totalBalance: Double {
        accounts.filter { $0.isActive && !$0.isBlocked }.reduce(0) { $0 + $1.balance }
    }
    
    var displayTotalBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = "₽"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: totalBalance)) ?? "\(totalBalance) ₽"
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        Publishers.CombineLatest($selectedFilter, $searchText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filter, search in
                self?.applyFilters(typeFilter: filter, search: search)
            }
            .store(in: &cancellables)
    }
    
    func loadAccounts(forUserId userId: Int64) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fetchedAccounts = SQLiteManager.shared.getAccountsForUser(userId)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.accounts = fetchedAccounts
                self.applyFilters(typeFilter: self.selectedFilter, search: self.searchText)
            }
        }
    }
    
    func selectAccount(_ account: Account) {
        selectedAccount = account
        
        if account.type == .card {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                let card = SQLiteManager.shared.getCardAccountForAccount(account.id)
                
                DispatchQueue.main.async {
                    self.cardDetails = card
                }
            }
        } else {
            cardDetails = nil
        }
    }
    
    func clearSelection() {
        selectedAccount = nil
        cardDetails = nil
    }
    
    func filterByType(_ type: AccountType?) {
        selectedFilter = type
    }
    
    private func applyFilters(typeFilter: AccountType?, search: String) {
        var result = accounts
        
        if let type = typeFilter {
            result = result.filter { $0.type == type }
        }
        
        if !search.isEmpty {
            let lowercasedSearch = search.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(lowercasedSearch) ||
                $0.type.displayName.lowercased().contains(lowercasedSearch)
            }
        }
        
        filteredAccounts = result
    }
    
    func refreshAccounts(forUserId userId: Int64) {
        loadAccounts(forUserId: userId)
    }
}
