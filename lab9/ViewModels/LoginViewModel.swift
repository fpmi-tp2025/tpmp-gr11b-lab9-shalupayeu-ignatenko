import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var login: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var loginSuccess: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        !login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func performLogin() {
        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedLogin.isEmpty else {
            errorMessage = "Введите логин"
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Введите пароль"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let success = SessionManager.shared.login(login: trimmedLogin, password: trimmedPassword)
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.loginSuccess = true
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Неверный логин или пароль"
                    self.loginSuccess = false
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
