import Foundation
import CoreLocation

/// Lightweight on-demand location service for the "Near you" Shop section.
///
/// Behavior:
/// - Lazy: nothing happens until `requestIfNeeded()` is called.
/// - One-shot: requests a single location fix per call, then stops the manager.
///   This keeps battery impact negligible and avoids continuous tracking.
/// - Cached: the latest coordinate stays in memory for the session, so repeat
///   visits to Shop don't re-prompt or re-query CoreLocation.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum Status: Equatable {
        case idle
        case requesting
        case unavailable
        case denied
        case ready
    }

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var status: Status = .idle

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Ask for permission (if undetermined) and request a single fix.
    func requestIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            if coordinate == nil {
                status = .requesting
                manager.requestLocation()
            } else {
                status = .ready
            }
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .unavailable
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        Task { @MainActor in
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                if self.coordinate == nil {
                    self.status = .requesting
                    self.manager.requestLocation()
                } else {
                    self.status = .ready
                }
            case .denied, .restricted:
                self.status = .denied
            case .notDetermined:
                self.status = .idle
            @unknown default:
                self.status = .unavailable
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        Task { @MainActor in
            self.coordinate = coord
            self.status = .ready
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            // If we have a cached fix, stay ready; otherwise mark unavailable.
            if self.coordinate == nil {
                self.status = .unavailable
            }
        }
    }
}

// MARK: - Distance helpers

extension CLLocationCoordinate2D {
    /// Great-circle distance in miles between two coordinates.
    func distanceMiles(to other: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1609.344
    }
}
