import SwiftUI

struct CurrencyRatesView: View {
    @StateObject private var viewModel = CurrencyViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Last updated info
                    lastUpdatedSection
                    
                    // Rates list
                    ratesList
                }
            }
            .navigationTitle("Курсы валют")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshRates()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if viewModel.rates.isEmpty {
                viewModel.loadRates()
            }
        }
    }
    
    // MARK: - Sections
    
    private var lastUpdatedSection: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            
            Text(viewModel.displayLastUpdated)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.secondary.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var ratesList: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.rates.isEmpty {
                loadingView
            } else if viewModel.rates.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(viewModel.rates) { rate in
                        CurrencyRateRow(rate: rate)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Загрузка курсов...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Курсы валют недоступны")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.loadRates()
            }) {
                Text("Обновить")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(.top, 100)
    }
}

// MARK: - Currency Rate Row

struct CurrencyRateRow: View {
    let rate: CurrencyRate
    
    var body: some View {
        HStack(spacing: 16) {
            // Currency icon
            ZStack {
                Circle()
                    .fill(currencyColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text(currencySymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(currencyColor)
            }
            
            // Currency info
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.displayCurrency)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(rate.currencyName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Rate value
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(rate.displayValue) ₽")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("за 1 \(rate.currency.uppercased())")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helpers
    
    private var currencyColor: Color {
        switch rate.currency.uppercased() {
        case "USD":
            return .green
        case "EUR":
            return .blue
        case "GBP":
            return .indigo
        case "JPY":
            return .red
        case "CNY":
            return .red
        case "CHF":
            return .orange
        default:
            return .gray
        }
    }
    
    private var currencySymbol: String {
        switch rate.currency.uppercased() {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "JPY":
            return "¥"
        case "CNY":
            return "元"
        case "CHF":
            return "Fr"
        default:
            return rate.currency.prefix(1).uppercased()
        }
    }
}

// MARK: - Preview

struct CurrencyRatesView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyRatesView()
    }
}
