# Project Name
Mobile Banking Application (iOS SwiftUI + SQLite)

## Description
This project is a mobile banking application for iOS that allows clients to log in, view their accounts, check balances, and explore additional features such as currency rates and branch locations. The system supports multiple account types including current, savings, credit, and card accounts. It also provides geolocation-based search for the nearest bank branch and integrates MapKit for visualization. Data persistence is handled using SQLite and session storage using UserDefaults.

## Installation
1. Clone repository
2. Open project in Xcode (iOS 15+)
3. Run `pod install` if needed (or Swift Package Manager setup)
4. Build and run on simulator or device

## Usage
- Launch app
- Login using credentials
- Navigate to "Accounts" to view active and blocked accounts
- Use "Currency Rates" for exchange rates
- Open "Map" to view branches and find nearest location

## Contributing
- iOS Developer: UI (SwiftUI screens), navigation, session management
- Backend/Data: SQLite schema, database manager, data fetching
- Location features: CoreLocation + MapKit integration
