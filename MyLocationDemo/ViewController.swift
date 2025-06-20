//
//  ViewController.swift
//  MyLocationDemo
//
// 
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    private let locationManager = LocationManager()
    private let mapView = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
    }

    private func setupUI() {
        view.backgroundColor = .white

        // 지도 뷰 설정
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true // 현재 위치 표시
        view.addSubview(mapView)

        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 지도 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }

    private func setupMapView() {
        // 초기 지도 영역 설정 (예: 서울 중심)
        let initialLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let region = MKCoordinateRegion(
            center: initialLocation,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        mapView.setRegion(region, animated: true)
    }

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        // 기존 핀 제거
        mapView.removeAnnotations(mapView.annotations)

        // 탭한 위치의 좌표 가져오기
        let touchPoint = gesture.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        // 디버깅 로그
        print("Tapped coordinate: \(coordinate.latitude), \(coordinate.longitude)")

        // 선택한 위치에 핀 추가
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "선택한 위치"
        mapView.addAnnotation(annotation)

        // 거리 계산 요청
        locationManager.checkDistanceToSelectedLocation(
            coordinate: coordinate,
            from: self
        ) { (success, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if success {
                print("Distance calculation completed")
            }
        }
    }

    // MKMapViewDelegate: 핀 커스터마이징
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil // 현재 위치 핀은 기본 스타일 사용
        }

        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        annotationView.canShowCallout = true
        return annotationView
    }
}
