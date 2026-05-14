import Foundation
import CoreLocation

struct Branch: Identifiable, Codable, Equatable {
    let id: Int64
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func distance(from userLocation: CLLocation) -> CLLocationDistance {
        return location.distance(from: userLocation)
    }
    
    func formattedDistance(from userLocation: CLLocation) -> String {
        let dist = distance(from: userLocation)
        if dist < 1000 {
            return String(format: "%.0f м", dist)
        } else {
            return String(format: "%.1f км", dist / 1000)
        }
    }
}
