import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private let loggedInKey = "isLoggedIn"
    private let userIdKey = "currentUserId"
    private let userLoginKey = "currentUserLogin"
    
    private init() {
        checkSession()
    }
    
    // MARK: - Session Management
    
    func login(login: String, password: String) -> Bool {
        guard let user = SQLiteManager.shared.getUserByLogin(login, password: password) else {
            return false
        }
        
        UserDefaults.standard.set(true, forKey: loggedInKey)
        UserDefaults.standard.set(user.id, forKey: userIdKey)
        UserDefaults.standard.set(user.login, forKey: userLoginKey)
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.isLoggedIn = true
        }
        
        return true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: loggedInKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userLoginKey)
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
    
    private func checkSession() {
        let isLogged = UserDefaults.standard.bool(forKey: loggedInKey)
        
        guard isLogged else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUser = nil
            }
            return
        }
        
        let userId = UserDefaults.standard.object(forKey: userIdKey) as? Int64 ?? 0
        
        if userId > 0, let user = SQLiteManager.shared.getUserById(userId) {
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
            }
        } else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUser = nil
            }
        }
    }
    
    func restoreSession() {
        checkSession()
    }
}
