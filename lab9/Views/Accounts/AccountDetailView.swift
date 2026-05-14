import SwiftUI

struct AccountDetailView: View {
    let account: Account
    let cardAccount: CardAccount?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Header Card
                accountHeaderCard
                
                // Account Details
                accountDetailsSection
                
                // Card Details (if applicable)
                if let card = cardAccount, account.type == .card {
                    cardDetailsSection(card: card)
                }
                
                // Status Info
                statusInfoSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Детали счета")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Sections
    
    private var accountHeaderCard: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(accountTypeColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: accountTypeIcon)
                    .font(.system(size: 36))
                    .foregroundColor(accountTypeColor)
            }
            
            // Account Name
            Text(account.name)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // Balance
            VStack(spacing: 4) {
                Text("Баланс")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(account.displayBalance)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(balanceColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var accountDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Информация о счете")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                detailRow(title: "Тип счета", value: account.type.displayName, icon: "doc.text", color: .blue)
                
                Divider().padding(.leading, 44)
                
                detailRow(title: "Номер счета", value: extractAccountNumber(from: account.name), icon: "number", color: .purple)
                
                Divider().padding(.leading, 44)
                
                detailRow(title: "Баланс", value: account.displayBalance, icon: "rublesign.circle", color: .green)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func cardDetailsSection(card: CardAccount) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Информация о карте")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                detailRow(title: "Тип карты", value: card.cardType.displayName, icon: "creditcard", color: .orange)
                
                Divider().padding(.leading, 44)
                
                detailRow(title: "Овердрафт", value: card.displayOverdraft, icon: "arrow.up.arrow.down", color: card.hasOverdraft ? .green : .red)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var statusInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статус")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                statusBadge(text: account.statusText, color: statusColor)
                
                if account.isBlocked {
                    statusBadge(text: "Заблокирован", color: .red)
                } else if account.isActive {
                    statusBadge(text: "Активен", color: .green)
                }
                
                if !account.isClosed {
                    statusBadge(text: "Открыт", color: .blue)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func detailRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .cornerRadius(20)
    }
    
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
    
    private var statusColor: Color {
        if account.isBlocked {
            return .red
        } else if account.isActive {
            return .green
        } else {
            return .gray
        }
    }
    
    private func extractAccountNumber(from name: String) -> String {
        let components = name.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let numbers = components.filter { !$0.isEmpty }
        return numbers.joined(separator: " ")
    }
}

// MARK: - Preview

struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let account = Account(
            id: 1,
            userId: 1,
            name: "Текущий счет №40817810099910001234",
            balance: 125430.50,
            type: .current,
            isActive: true,
            isBlocked: false,
            isClosed: false
        )
        
        let card = CardAccount(accountId: 1, cardType: .salary, overdraftLimit: 30000)
        
        NavigationView {
            AccountDetailView(account: account, cardAccount: card)
        }
    }
}
