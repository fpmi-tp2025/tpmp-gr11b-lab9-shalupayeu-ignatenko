import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @State private var showFilters: Bool = false
    @State private var selectedAccountForDetail: Account? = nil
    @State private var showDetailSheet: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Summary Card
                    summaryCard
                    
                    // Filter Bar
                    filterBar
                    
                    // Search Bar
                    searchBar
                    
                    // Accounts List
                    accountsList
                }
            }
            .navigationTitle("Мои счета")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        guard let userId = SessionManager.shared.currentUser?.id else { return }
                        viewModel.refreshAccounts(forUserId: userId)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            guard let userId = SessionManager.shared.currentUser?.id else { return }
            viewModel.loadAccounts(forUserId: userId)
        }
        .sheet(isPresented: $showDetailSheet) {
            if let account = selectedAccountForDetail {
                NavigationView {
                    AccountDetailView(
                        account: account,
                        cardAccount: viewModel.cardDetails
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Готово") {
                                showDetailSheet = false
                                viewModel.clearSelection()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Total Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Общий баланс")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.displayTotalBalance)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("\(viewModel.activeCount) активных")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.blockedCount > 0 {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("\(viewModel.blockedCount) заблок.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "Все", type: nil)
                
                ForEach(AccountType.allCases) { type in
                    filterChip(title: type.displayName, type: type)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private func filterChip(title: String, type: AccountType?) -> some View {
        let isSelected = viewModel.selectedFilter == type
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.filterByType(type)
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color(.secondarySystemGroupedBackground)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Поиск по названию или типу...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var accountsList: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 60)
            } else if viewModel.filteredAccounts.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredAccounts) { account in
                        AccountCardView(account: account) {
                            viewModel.selectAccount(account)
                            selectedAccountForDetail = account
                            showDetailSheet = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(viewModel.searchText.isEmpty ? "Счета не найдены" : "Ничего не найдено")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            if !viewModel.searchText.isEmpty {
                Text("Попробуйте изменить параметры поиска")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }
}

// MARK: - Account Card View

struct AccountCardView: View {
    let account: Account
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accountTypeColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: accountTypeIcon)
                        .font(.system(size: 22))
                        .foregroundColor(accountTypeColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(account.type.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accountTypeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accountTypeColor.opacity(0.12))
                            .cornerRadius(8)
                        
                        if account.isBlocked {
                            Text("Заблокирован")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(account.displayBalance)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(balanceColor)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helpers
    
    private var accountTypeColor: Color {
        switch account.type {
        case .current:
            return .blue
        case .savings:
            return .green
        case .credit:
            return .orange
        case .card:
            return .purple
        }
    }
    
    private var accountTypeIcon: String {
        switch account.type {
        case .current:
            return "doc.text.fill"
        case .savings:
            return "piggy.bank.fill"
        case .credit:
            return "creditcard.fill"
        case .card:
            return "creditcard.circle.fill"
        }
    }
    
    private var balanceColor: Color {
        if account.balance < 0 {
            return .red
        }
        return .primary
    }
}

// MARK: - Preview

struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}
