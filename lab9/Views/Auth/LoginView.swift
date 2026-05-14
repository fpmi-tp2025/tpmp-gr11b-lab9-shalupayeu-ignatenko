import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Login Form
                        loginFormSection
                        
                        // Demo accounts info
                        demoAccountsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
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
            
            Text("Банк")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Мобильный банк")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var loginFormSection: some View {
        VStack(spacing: 20) {
            // Login Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Логин")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    TextField("Введите логин", text: $viewModel.login)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Пароль")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    if isPasswordVisible {
                        TextField("Введите пароль", text: $viewModel.password)
                            .textContentType(.password)
                    } else {
                        SecureField("Введите пароль", text: $viewModel.password)
                            .textContentType(.password)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPasswordVisible.toggle()
                        }
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Login Button
            Button(action: {
                hideKeyboard()
                viewModel.performLogin()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else {
                        Text("Войти")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: viewModel.isFormValid ? [.blue, .purple] : [.gray.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: viewModel.isFormValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var demoAccountsSection: some View {
        VStack(spacing: 12) {
            Text("Демо-аккаунты")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                demoAccountRow(login: "ivanov", password: "password123", name: "Иванов")
                demoAccountRow(login: "petrova", password: "qwerty456", name: "Петрова")
                demoAccountRow(login: "sidorov", password: "bank789", name: "Сидоров")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func demoAccountRow(login: String, password: String, name: String) -> some View {
        Button(action: {
            viewModel.login = login
            viewModel.password = password
        }) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("логин: \(login)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue.opacity(0.6))
                    .font(.system(size: 18))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Keyboard Helper

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
