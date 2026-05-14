import Foundation
import SQLite3
import Combine

class SQLiteManager: ObservableObject {
    static let shared = SQLiteManager()
    
    private var db: OpaquePointer?
    private let dbName = "bankapp.sqlite"
    
    private var dbURL: URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(dbName)
    }
    
    private init() {
        openDatabase()
        createTables()
        insertDemoDataIfNeeded()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Lifecycle
    
    private func openDatabase() {
        let path = dbURL.path
        
        if sqlite3_open(path, &db) == SQLITE_OK {
            print("База данных успешно открыта по пути: \(path)")
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("Ошибка открытия БД: \(errorMessage)")
            db = nil
        }
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    // MARK: - Table Creation
    
    private func createTables() {
        guard db != nil else { return }
        
        let createUsersTable = """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                login TEXT NOT NULL UNIQUE,
                password TEXT NOT NULL
            );
        """
        
        let createAccountsTable = """
            CREATE TABLE IF NOT EXISTS accounts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                balance REAL NOT NULL DEFAULT 0,
                type TEXT NOT NULL CHECK(type IN ('current', 'savings', 'credit', 'card')),
                is_active INTEGER NOT NULL DEFAULT 1,
                is_blocked INTEGER NOT NULL DEFAULT 0,
                is_closed INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """
        
        let createCardAccountsTable = """
            CREATE TABLE IF NOT EXISTS card_accounts (
                account_id INTEGER PRIMARY KEY,
                card_type TEXT NOT NULL CHECK(card_type IN ('salary', 'savings', 'credit')),
                overdraft_limit REAL,
                FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
            );
        """
        
        let createBranchesTable = """
            CREATE TABLE IF NOT EXISTS branches (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                address TEXT NOT NULL
            );
        """
        
        let createCurrencyRatesTable = """
            CREATE TABLE IF NOT EXISTS currency_rates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                currency TEXT NOT NULL UNIQUE,
                value REAL NOT NULL,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        let tables = [createUsersTable, createAccountsTable, createCardAccountsTable, createBranchesTable, createCurrencyRatesTable]
        
        for table in tables {
            execute(table)
        }
    }
    
    // MARK: - Demo Data
    
    private func insertDemoDataIfNeeded() {
        guard db != nil else { return }
        
        let checkUsers = "SELECT COUNT(*) FROM users;"
        guard let count = queryInt(checkUsers) else { return }
        
        if count > 0 { return }
        
        // Insert demo users
        let insertUser1 = "INSERT INTO users (login, password) VALUES ('ivanov', 'password123');"
        let insertUser2 = "INSERT INTO users (login, password) VALUES ('petrova', 'qwerty456');"
        let insertUser3 = "INSERT INTO users (login, password) VALUES ('sidorov', 'bank789');"
        
        execute(insertUser1)
        execute(insertUser2)
        execute(insertUser3)
        
        // Insert demo accounts for user 1 (ivanov)
        let accountsUser1 = [
            (1, "Текущий счет №40817810099910001234", 125430.50, "'current'", 1, 0, 0),
            (1, "Сберегательный счет №40817810999910005678", 500000.00, "'savings'", 1, 0, 0),
            (1, "Кредитный счет №40817810899910009012", -150000.75, "'credit'", 1, 0, 0),
            (1, "Зарплатная карта №40817810799910003456", 45600.00, "'card'", 1, 0, 0),
            (1, "Старая карта (заблокирована)", 0.00, "'card'", 0, 1, 0),
            (1, "Закрытый счет (не должен отображаться)", 0.00, "'current'", 0, 0, 1)
        ]
        
        for account in accountsUser1 {
            let query = """
                INSERT INTO accounts (user_id, name, balance, type, is_active, is_blocked, is_closed)
                VALUES (\(account.0), '\(account.1)', \(account.2), \(account.3), \(account.4), \(account.5), \(account.6));
            """
            execute(query)
        }
        
        // Insert card account details for user 1
        let cardAccountsUser1 = [
            (4, "'salary'", 30000.00),
            (5, "'savings'", 0.00)
        ]
        
        for card in cardAccountsUser1 {
            let query = """
                INSERT INTO card_accounts (account_id, card_type, overdraft_limit)
                VALUES (\(card.0), \(card.1), \(card.2));
            """
            execute(query)
        }
        
        // Insert demo accounts for user 2 (petrova)
        let accountsUser2 = [
            (2, "Основной счет №40817810699910007890", 280000.00, "'current'", 1, 0, 0),
            (2, "Кредитная карта №40817810599910006543", -75000.00, "'card'", 1, 0, 0),
            (2, "Вклад №40817810499910003210", 1000000.00, "'savings'", 1, 0, 0)
        ]
        
        for account in accountsUser2 {
            let query = """
                INSERT INTO accounts (user_id, name, balance, type, is_active, is_blocked, is_closed)
                VALUES (\(account.0), '\(account.1)', \(account.2), \(account.3), \(account.4), \(account.5), \(account.6));
            """
            execute(query)
        }
        
        let cardAccountsUser2 = [
            (8, "'credit'", 50000.00)
        ]
        
        for card in cardAccountsUser2 {
            let query = """
                INSERT INTO card_accounts (account_id, card_type, overdraft_limit)
                VALUES (\(card.0), \(card.1), \(card.2));
            """
            execute(query)
        }
        
        // Insert demo accounts for user 3 (sidorov)
        let accountsUser3 = [
            (3, "Единый счет №40817810399910001122", 15.45, "'current'", 1, 0, 0),
            (3, "Счет (заблокирован)", 5000.00, "'savings'", 0, 1, 0)
        ]
        
        for account in accountsUser3 {
            let query = """
                INSERT INTO accounts (user_id, name, balance, type, is_active, is_blocked, is_closed)
                VALUES (\(account.0), '\(account.1)', \(account.2), \(account.3), \(account.4), \(account.5), \(account.6));
            """
            execute(query)
        }
        
        // Insert demo branches (Moscow)
        let branches = [
            ("'Центральный офис'", 55.7558, 37.6173, "'Москва, ул. Тверская, д. 10'"),
            ("'Отделение на Арбате'", 55.7520, 37.5955, "'Москва, ул. Арбат, д. 25'"),
            ("'Отделение Киевское'", 55.7440, 37.5660, "'Москва, Киевская ул., д. 7'"),
            ("'Отделение Маяковская'", 55.7700, 37.5950, "'Москва, ул. Большая Садовая, д. 14'"),
            ("'Отделение Таганка'", 55.7400, 37.6500, "'Москва, ул. Нижняя Радищевская, д. 2'"),
            ("'Отделение Сокольники'", 55.7900, 37.6800, "'Москва, Сокольническая пл., д. 4'")
        ]
        
        for branch in branches {
            let query = """
                INSERT INTO branches (name, latitude, longitude, address)
                VALUES (\(branch.0), \(branch.1), \(branch.2), \(branch.3));
            """
            execute(query)
        }
        
        // Insert demo currency rates
        let rates = [
            ("'USD'", 92.45),
            ("'EUR'", 100.20),
            ("'GBP'", 117.80),
            ("'JPY'", 0.61),
            ("'CNY'", 12.75),
            ("'CHF'", 104.50)
        ]
        
        for rate in rates {
            let query = """
                INSERT INTO currency_rates (currency, value, updated_at)
                VALUES (\(rate.0), \(rate.1), datetime('now'));
            """
            execute(query)
        }
    }
    
    // MARK: - SQL Helpers
    
    private func execute(_ query: String) {
        guard db != nil else {
            print("БД не открыта")
            return
        }
        
        if sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("Ошибка SQL: \(errorMessage)")
            print("Запрос: \(query)")
        }
    }
    
    private func queryInt(_ query: String) -> Int? {
        guard db != nil else { return nil }
        
        var statement: OpaquePointer?
        var result: Int?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                result = Int(sqlite3_column_int(statement, 0))
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    // MARK: - User Operations
    
    func getUserByLogin(_ login: String, password: String) -> User? {
        guard db != nil else { return nil }
        
        let query = "SELECT id, login, password FROM users WHERE login = ? AND password = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        sqlite3_bind_text(statement, 1, (login as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, nil)
        
        var user: User?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let login = String(cString: sqlite3_column_text(statement, 1))
            let password = String(cString: sqlite3_column_text(statement, 2))
            user = User(id: id, login: login, password: password)
        }
        
        sqlite3_finalize(statement)
        return user
    }
    
    func getUserById(_ id: Int64) -> User? {
        guard db != nil else { return nil }
        
        let query = "SELECT id, login, password FROM users WHERE id = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        sqlite3_bind_int64(statement, 1, id)
        
        var user: User?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let login = String(cString: sqlite3_column_text(statement, 1))
            let password = String(cString: sqlite3_column_text(statement, 2))
            user = User(id: id, login: login, password: password)
        }
        
        sqlite3_finalize(statement)
        return user
    }
    
    // MARK: - Account Operations
    
    func getAccountsForUser(_ userId: Int64) -> [Account] {
        guard db != nil else { return [] }
        
        let query = """
            SELECT id, user_id, name, balance, type, is_active, is_blocked, is_closed
            FROM accounts
            WHERE user_id = ? AND is_closed = 0
            ORDER BY is_blocked ASC, name ASC;
        """
        
        var statement: OpaquePointer?
        var accounts: [Account] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        sqlite3_bind_int64(statement, 1, userId)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let userId = sqlite3_column_int64(statement, 1)
            let name = String(cString: sqlite3_column_text(statement, 2))
            let balance = sqlite3_column_double(statement, 3)
            let typeStr = String(cString: sqlite3_column_text(statement, 4))
            let isActive = sqlite3_column_int(statement, 5) != 0
            let isBlocked = sqlite3_column_int(statement, 6) != 0
            let isClosed = sqlite3_column_int(statement, 7) != 0
            
            if let type = AccountType(rawValue: typeStr) {
                let account = Account(
                    id: id,
                    userId: userId,
                    name: name,
                    balance: balance,
                    type: type,
                    isActive: isActive,
                    isBlocked: isBlocked,
                    isClosed: isClosed
                )
                accounts.append(account)
            }
        }
        
        sqlite3_finalize(statement)
        return accounts
    }
    
    func getAccountById(_ accountId: Int64) -> Account? {
        guard db != nil else { return nil }
        
        let query = """
            SELECT id, user_id, name, balance, type, is_active, is_blocked, is_closed
            FROM accounts
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        sqlite3_bind_int64(statement, 1, accountId)
        
        var account: Account?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let userId = sqlite3_column_int64(statement, 1)
            let name = String(cString: sqlite3_column_text(statement, 2))
            let balance = sqlite3_column_double(statement, 3)
            let typeStr = String(cString: sqlite3_column_text(statement, 4))
            let isActive = sqlite3_column_int(statement, 5) != 0
            let isBlocked = sqlite3_column_int(statement, 6) != 0
            let isClosed = sqlite3_column_int(statement, 7) != 0
            
            if let type = AccountType(rawValue: typeStr) {
                account = Account(
                    id: id,
                    userId: userId,
                    name: name,
                    balance: balance,
                    type: type,
                    isActive: isActive,
                    isBlocked: isBlocked,
                    isClosed: isClosed
                )
            }
        }
        
        sqlite3_finalize(statement)
        return account
    }
    
    // MARK: - Card Account Operations
    
    func getCardAccountForAccount(_ accountId: Int64) -> CardAccount? {
        guard db != nil else { return nil }
        
        let query = """
            SELECT account_id, card_type, overdraft_limit
            FROM card_accounts
            WHERE account_id = ?;
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        sqlite3_bind_int64(statement, 1, accountId)
        
        var cardAccount: CardAccount?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let accId = sqlite3_column_int64(statement, 0)
            let cardTypeStr = String(cString: sqlite3_column_text(statement, 1))
            let overdraftLimit = sqlite3_column_double(statement, 2)
            
            if let cardType = CardAccountType(rawValue: cardTypeStr) {
                cardAccount = CardAccount(
                    accountId: accId,
                    cardType: cardType,
                    overdraftLimit: overdraftLimit > 0 ? overdraftLimit : nil
                )
            }
        }
        
        sqlite3_finalize(statement)
        return cardAccount
    }
    
    // MARK: - Branch Operations
    
    func getAllBranches() -> [Branch] {
        guard db != nil else { return [] }
        
        let query = "SELECT id, name, latitude, longitude, address FROM branches ORDER BY name;"
        var statement: OpaquePointer?
        var branches: [Branch] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let name = String(cString: sqlite3_column_text(statement, 1))
            let latitude = sqlite3_column_double(statement, 2)
            let longitude = sqlite3_column_double(statement, 3)
            let address = String(cString: sqlite3_column_text(statement, 4))
            
            let branch = Branch(id: id, name: name, latitude: latitude, longitude: longitude, address: address)
            branches.append(branch)
        }
        
        sqlite3_finalize(statement)
        return branches
    }
    
    // MARK: - Currency Rate Operations
    
    func getAllCurrencyRates() -> [CurrencyRate] {
        guard db != nil else { return [] }
        
        let query = "SELECT id, currency, value, updated_at FROM currency_rates ORDER BY currency;"
        var statement: OpaquePointer?
        var rates: [CurrencyRate] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let currency = String(cString: sqlite3_column_text(statement, 1))
            let value = sqlite3_column_double(statement, 2)
            
            let dateString = String(cString: sqlite3_column_text(statement, 3))
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var updatedAt = Date()
            if let date = dateFormatter.date(from: dateString) {
                updatedAt = date
            } else {
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = fallbackFormatter.date(from: dateString) {
                    updatedAt = date
                }
            }
            
            let rate = CurrencyRate(id: id, currency: currency, value: value, updatedAt: updatedAt)
            rates.append(rate)
        }
        
        sqlite3_finalize(statement)
        return rates
    }
    
    func updateCurrencyRate(currency: String, value: Double) {
        guard db != nil else { return }
        
        let query = """
            INSERT INTO currency_rates (currency, value, updated_at)
            VALUES (?, ?, datetime('now'))
            ON CONFLICT(currency) DO UPDATE SET
                value = excluded.value,
                updated_at = excluded.updated_at;
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return
        }
        
        sqlite3_bind_text(statement, 1, (currency as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 2, value)
        
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
    
    func getLastCurrencyUpdate() -> Date? {
        guard db != nil else { return nil }
        
        let query = "SELECT MAX(updated_at) FROM currency_rates;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        var lastUpdate: Date?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let dateString = sqlite3_column_text(statement, 0) {
                let dateStr = String(cString: dateString)
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = dateFormatter.date(from: dateStr) {
                    lastUpdate = date
                } else {
                    let fallbackFormatter = DateFormatter()
                    fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
                    lastUpdate = fallbackFormatter.date(from: dateStr)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return lastUpdate
    }
}
