import Foundation
import CoreLocation
import Combine
import MapKit

class BranchMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var branches: [Branch] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userLocation: CLLocation?
    @Published var nearestBranch: Branch?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    @Published var locationPermissionDenied: Bool = false
    @Published var showNearestBranch: Bool = false
    @Published var selectedBranch: Branch?
    
    private var locationManager: CLLocationManager?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        let status = locationManager?.authorizationStatus ?? .notDetermined
        
        switch status {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager?.startUpdatingLocation()
        case .denied, .restricted:
            locationPermissionDenied = true
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.userLocation = location
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            
            self.findNearestBranch()
        }
        
        locationManager?.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Не удалось определить местоположение"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionDenied = false
            manager.startUpdatingLocation()
        case .denied, .restricted:
            locationPermissionDenied = true
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func loadBranches() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fetchedBranches = SQLiteManager.shared.getAllBranches()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.branches = fetchedBranches
                
                if fetchedBranches.isEmpty {
                    self.errorMessage = "Отделения временно недоступны"
                } else if self.userLocation != nil {
                    self.findNearestBranch()
                }
            }
        }
    }
    
    func findNearestBranch() {
        guard let userLocation = userLocation, !branches.isEmpty else {
            nearestBranch = nil
            return
        }
        
        var closest: Branch?
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for branch in branches {
            let distance = branch.distance(from: userLocation)
            if distance < minDistance {
                minDistance = distance
                closest = branch
            }
        }
        
        nearestBranch = closest
        
        if let branch = closest {
            region = MKCoordinateRegion(
                center: branch.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func navigateToBranch(_ branch: Branch) {
        selectedBranch = branch
        
        let placemark = MKPlacemark(coordinate: branch.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = branch.name
        
        let options = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: options)
    }
    
    func centerOnUser() {
        guard let location = userLocation else {
            requestLocationPermission()
            return
        }
        
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func centerOnNearestBranch() {
        guard let branch = nearestBranch else {
            errorMessage = "Ближайшее отделение не найдено"
            return
        }
        
        region = MKCoordinateRegion(
            center: branch.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
        
        selectedBranch = branch
    }
}
