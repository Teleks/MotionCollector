//
//  GeoLocationCollector.swift
//  MotionCollector
//
//  Created by Nikita Egoshin on 06.12.2019.
//  Copyright © 2019 Aleksei Degtiarev. All rights reserved.
//

import Foundation
import CoreLocation


protocol GeoLocationCollectorDelegate: class {
    func geoLocationCollectorDidStart(_ collector: GeoLocationCollector)
    func geoLocationCollectorDidStop(_ collector: GeoLocationCollector)
    
    func geoLocationCollector(_ collector: GeoLocationCollector, didRecieveHeading heading: CLHeading)
    func geoLocationCollector(_ collector: GeoLocationCollector, didRecieveLocations locations: [CLLocation])
}

class GeoLocationCollector: NSObject, CLLocationManagerDelegate {
    
    static let `default` = GeoLocationCollector()
    
    var isRunning: Bool = false
    weak var delegate: GeoLocationCollectorDelegate?
    
    private let manager = CLLocationManager()
    
    
    // MARK: - Lifecycle
    
    deinit {
        isRunning = false
    }
    
    
    // MARK: - Control
    
    func start() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            run()
        } else {
            manager.requestAlwaysAuthorization()
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
        
        isRunning = false
        delegate?.geoLocationCollectorDidStop(self)
    }
    
    
    // MARK: - Private
    
    func run() {
        manager.startUpdatingHeading()
        manager.startUpdatingLocation()
        
        delegate?.geoLocationCollectorDidStart(self)
    }
    
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedAlways || status == .authorizedWhenInUse) && !isRunning  {
            run()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.geoLocationCollector(self, didRecieveHeading: newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.geoLocationCollector(self, didRecieveLocations: locations)
    }
}
