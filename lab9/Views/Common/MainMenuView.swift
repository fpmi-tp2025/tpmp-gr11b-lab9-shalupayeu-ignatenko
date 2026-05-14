import SwiftUI

struct MainMenuView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTab: Tab = .accounts
    @State private var showLogoutConfirmation: Bool = false
    
    enum Tab {
        case accounts
        case currency
        case map
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Счета")
                }
                .tag(Tab.accounts)
            
            CurrencyRatesView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Валюты")
                }
                .tag(Tab.currency)
            
            BranchMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Карта")
                }
                .tag(Tab.map)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(Tab.profile)
        }
        .accentColor(.blue)
        .environmentObject(sessionManager)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var showLogoutConfirmation: Bool = false
    @State private var showAboutSheet: Bool = false
    @State private var showHelpSheet: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Card
                        userCard
                        
                        // Menu Sections
                        menuSection(title: "Приложение", items: [
                            MenuItem(icon: "info.circle.fill", title: "О приложении", color: .blue) {
                                showAboutSheet = true
                            },
                            MenuItem(icon: "questionmark.circle.fill", title: "Помощь", color: .green) {
                                showHelpSheet = true
                            }
                        ])
                        
                        menuSection(title: "Безопасность", items: [
                            MenuItem(icon: "lock.shield.fill", title: "Сменить пароль", color: .orange) {
                                // Placeholder
                            },
                            MenuItem(icon: "touchid", title: "Биометрия", color: .purple) {
                                // Placeholder
                            }
                        ])
                        
                        menuSection(title: "Сеанс", items: [
                            MenuItem(icon: "arrow.right.square.fill", title: "Выйти", color: .red) {
                                showLogoutConfirmation = true
                            }
                        ])
                        
                        // Version
                        Text("Версия 1.0.0 (Build 2024.05)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Выход из системы", isPresented: $showLogoutConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                sessionManager.logout()
            }
        } message: {
            Text("Вы уверены, что хотите выйти?")
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpSheet()
        }
    }
    
    // MARK: - Sections
    
    private var userCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text(userInitials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(userDisplayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("@\(sessionManager.currentUser?.login ?? "")")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func menuSection(title: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    MenuItemView(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helpers
    
    private var userInitials: String {
        guard let login = sessionManager.currentUser?.login else { return "?" }
        return String(login.prefix(1)).uppercased()
    }
    
    private var userDisplayName: String {
        guard let login = sessionManager.currentUser?.login else { return "Пользователь" }
        return login.capitalized
    }
}

// MARK: - Menu Item

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
}

struct MenuItemView: View {
    let item: MenuItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(item.color)
                    .frame(width: 32, height: 32)
                    .background(item.color.opacity(0.15))
                    .cornerRadius(8)
                
                Text(item.title)
                    .font(.system(size: 17))
                    .foregroundColor(item.color == .red ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - About Sheet

struct AboutSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Банк")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Версия 1.0.0")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        infoBlock(title: "О приложении", content: "Мобильное банковское приложение для управления счетами, просмотра курсов валют и поиска отделений банка.")
                        
                        infoBlock(title: "Технологии", content: "• SwiftUI\n• SQLite\n• CoreLocation\n• MapKit\n• UserDefaults")
                        
                        infoBlock(title: "Возможности", content: "• Авторизация пользователей\n• Просмотр счетов\n• Курсы валют в реальном времени\n• Карта отделений\n• Поиск ближайшего отделения")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("О приложении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func infoBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Help Sheet

struct HelpSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    helpSection(title: "Авторизация", icon: "lock.fill", color: .blue, items: [
                        "Введите логин и пароль",
                        "Нажмите кнопку \"Войти\"",
                        "При успешном входе откроется главное меню"
                    ])
                    
                    helpSection(title: "Просмотр счетов", icon: "doc.text.fill", color: .green, items: [
                        "Выберите вкладку \"Счета\"",
                        "Используйте фильтры по типу счета",
                        "Нажмите на счет для просмотра деталей"
                    ])
                    
                    helpSection(title: "Курсы валют", icon: "dollarsign.circle.fill", color: .orange, items: [
                        "Выберите вкладку \"Валюты\"",
                        "Потяните вниз для обновления",
                        "Курсы обновляются в реальном времени"
                    ])
                    
                    helpSection(title: "Карта отделений", icon: "map.fill", color: .purple, items: [
                        "Выберите вкладку \"Карта\"",
                        "Разрешите доступ к геолокации",
                        "Нажмите \"Ближайшее\" для поиска"
                    ])
                    
                    helpSection(title: "Выход из системы", icon: "arrow.right.square.fill", color: .red, items: [
                        "Перейдите во вкладку \"Профиль\"",
                        "Нажмите \"Выйти\"",
                        "Подтвердите действие"
                    ])
                }
                .padding(20)
            }
            .navigationTitle("Помощь")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func helpSection(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(color)
                        
                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Preview

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
