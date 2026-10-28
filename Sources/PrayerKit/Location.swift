import Adhan
import CoreLocation
import Foundation

/// The Mac's location. Starts from the cached fix, so it works offline, then follows
/// CoreLocation's updates and caches each one.
@MainActor
public final class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// The latest fix, or nil if there has never been one.
    @Published public private(set) var coordinates: Coordinates?
    /// True when location access is denied or restricted, including when Location
    /// Services are off for the whole Mac.
    @Published public private(set) var isDenied = false

    private let defaults: UserDefaults
    private let manager = CLLocationManager()

    /// Create it on the main thread: CoreLocation calls the delegate on the thread
    /// that created the manager.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        coordinates = defaults.cachedCoordinates
        super.init()
        // Setting the delegate triggers locationManagerDidChangeAuthorization.
        manager.delegate = self
    }

    nonisolated public func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        MainActor.assumeIsolated {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                isDenied = true
            default:
                isDenied = false
                // Not a one-off request: the app runs for days, so keep retrying after a
                // failed fix and follow the Mac when it moves to another city.
                manager.startMonitoringSignificantLocationChanges()
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        MainActor.assumeIsolated {
            self.coordinates = coordinates
            defaults.cachedCoordinates = coordinates
        }
    }

    // Keep the cached fix: a failed refresh, say while offline, doesn't make it wrong.
    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

extension UserDefaults {
    /// The last location fix, kept between launches.
    public var cachedCoordinates: Coordinates? {
        get { data(forKey: "coordinates").flatMap { try? JSONDecoder().decode(Coordinates.self, from: $0) } }
        set { set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: "coordinates") }
    }
}
