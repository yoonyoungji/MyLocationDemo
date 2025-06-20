//
//  LocationManager.swift
//  MyLocationDemo
//
//  
//

import Foundation
import CoreLocation
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var completion: ((Bool, Error?) -> Void)?
    private var pendingCoordinate: CLLocationCoordinate2D?
    private weak var pendingViewController: UIViewController?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func checkDistanceToSelectedLocation(coordinate: CLLocationCoordinate2D, from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        self.completion = completion
        self.pendingCoordinate = coordinate
        self.pendingViewController = viewController

        switch locationManager.authorizationStatus {
        case .notDetermined:
            showPermissionAlert(from: viewController) {
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            showPermissionDeniedAlert(from: viewController)
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]))
            self.clearPending()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            // calculateDistance는 위치 업데이트 후 호출
        @unknown default:
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"]))
            self.clearPending()
        }
    }

    private func showPermissionAlert(from viewController: UIViewController, completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "위치 권한 요청",
            message: "선택한 위치와 현재 위치 간 거리를 확인하려면 위치 권한이 필요합니다. 허용하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "허용", style: .default) { _ in
            completion()
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            self.completion?(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled permission request"]))
            self.clearPending()
        })
        viewController.present(alert, animated: true)
    }

    private func showPermissionDeniedAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        viewController.present(alert, animated: true)
    }

    private func calculateDistance(to coordinate: CLLocationCoordinate2D, from viewController: UIViewController) {
        let selectedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // 역지오코딩으로 선택한 위치의 주소 가져오기
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(selectedLocation) { [weak self] (placemarks, error) in
            guard let self = self else { return }

            var addressString = "선택한 위치"
            if let placemark = placemarks?.first {
                addressString = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard let currentLocation = self.currentLocation else {
                self.showErrorAlert(from: viewController, message: "현재 위치를 가져올 수 없습니다. 잠시 후 다시 시도해주세요.")
                self.completion?(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current location unavailable"]))
                self.clearPending()
                return
            }

            let distance = currentLocation.distance(from: selectedLocation)
            let message = "선택한 위치(\(addressString))는 현재 위치로부터 \(Int(distance))미터 떨어져 있습니다."
            self.showResultAlert(from: viewController, message: message)

            self.completion?(true, nil)
            self.clearPending()
        }
    }

    private func showErrorAlert(from viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        viewController.present(alert, animated: true)
    }

    private func showResultAlert(from viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: "거리 확인 결과", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        viewController.present(alert, animated: true)
    }

    private func clearPending() {
        self.completion = nil
        self.pendingCoordinate = nil
        self.pendingViewController = nil
        self.locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location
        print("Updated currentLocation: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // 대기 중인 계산이 있으면 실행
        if let coordinate = pendingCoordinate, let viewController = pendingViewController {
            calculateDistance(to: coordinate, from: viewController)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        completion?(false, error)
        clearPending()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Authorization status changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            completion?(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]))
            clearPending()
        default:
            break
        }
    }
}
