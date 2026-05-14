# Class Diagram (Textual)

## User
- id
- login
- password

## Account
- id
- name
- balance
- type
- isActive
- isBlocked

## CardAccount
- cardType
- overdraftLimit

## Branch
- id
- name
- latitude
- longitude
- address

## SessionManager
- login()
- logout()
- isLoggedIn

## SQLiteManager
- openDatabase()
- createTables()
- fetchAccounts()
