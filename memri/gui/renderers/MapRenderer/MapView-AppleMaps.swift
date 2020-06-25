//
//  MapView.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//
#if targetEnvironment(macCatalyst)
import Foundation
import SwiftUI
import Combine
import MapKit

extension MapView {
    func makeUIView(context: Context) -> MKMapView {
        
        let mapView: MKMapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        context.coordinator.setup(mapView)
        
        mapView.alpha = 0
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.mapModel.dataItems = dataItems
        context.coordinator.mapModel.locationKey = locationKey
        context.coordinator.mapModel.addressKey = addressKey
        context.coordinator.mapModel.labelKey = labelKey
        context.coordinator.mapModel.mapStyle = mapStyle
    }
    
    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Implementing MGLMapViewDelegate
    
    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var mapModel: MapModel = MapModel()
        
        var mapView: MKMapView?
        
        var cancellableBag: Set<AnyCancellable> = []
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            
            mapModel.didChange.sink { [weak self] in
                self?.updateFromModel()
            }
            .store(in: &cancellableBag)
        }
        
        func setup(_ mapView: MKMapView) {
            self.mapView = mapView
            mapView.register(
                MapMarkerView.self,
                forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        }
        
        var firstSet: Bool = true
        func updateFromModel() {
            guard let mapView = mapView else { return }
            
            let newAnnotations = mapModel.items.map { item -> MKAnnotation in
                let annotation = MapAnnotation(
                    title: item.label,
                    coordinate: item.coordinate,
                    dataItem: item.dataItem
                )
                return annotation
            }
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(newAnnotations)
            
            if !mapModel.items.isEmpty {
                UIView.animate(withDuration: 0.3) {
                    mapView.alpha = 1
                }
                fitDataInView(animated: !firstSet)
                firstSet = false
            }
        }
        
        func fitDataInView(animated: Bool = true) {
            mapView?.showAnnotations(mapView?.annotations ?? [], animated: animated)
        }
        
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//
//        }
        
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            // ONPRESS
            guard let annotation = view.annotation as? MapAnnotation, let dataItem = annotation.dataItem else { return }
            parent.onPress?(dataItem)
        }
    }
}

class MapAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let dataItem: MapItem?
    
    init(
        title: String?,
        coordinate: CLLocationCoordinate2D,
        dataItem: MapItem?
    ) {
        self.title = title
        self.coordinate = coordinate
        self.dataItem = dataItem
        
        super.init()
    }
}

class MapMarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            canShowCallout = true
            calloutOffset = .zero
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            //markerTintColor
        }
    }
}



#endif

/*
struct MapView: UIViewRepresentable {
    @ObservedObject
    var mapModel: MapModel

    var maxInitialZoom: Double = 16

    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if let addresses = addresses {
            var count = 0
            for address in addresses {
                if address.location == nil {
                    count += 1
                    address.retrieveLocation { error in
                        count -= 1
                        
                        if count == 0 {
                            self.setRegionForCollection(view)
                        }
                    }
                }
            }
            
            if count == 0 {
                self.setRegionForCollection(view)
            }
            return
        }
        else if let _ = locations {
            self.setRegionForCollection(view)
            return
        }
        else if let address = address {
            if address.location == nil {
                // TODO Refactor: Passing realm here is very ugly
                address.retrieveLocation { error in
                    // TODO Refactor: Should the UI just auto update because the data item has updated?
                    if error == nil {
                        self.setRegion(view, address.location)
                    }
                }
                return
            }
        }
        
        setRegion(view, self.location ?? address?.location)
    }
    
    func setRegionForCollection(_ view: MKMapView) {
        let locations = self.locations ?? self.addresses?.map({ $0.location }).filter({ $0 != nil })
        
        var dLat:[Double] = [100,0], dLong:[Double] = [100,0]
        if let locations = locations{
            for location in locations {
                if let lat = location?.latitude.value, let long = location?.longitude.value{
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    
                    dLat[0] = min(dLat[0], coordinate.latitude)
                    dLat[1] = max(dLat[1], coordinate.latitude)
                    
                    dLong[0] = min(dLong[0], coordinate.longitude)
                    dLong[1] = max(dLong[1], coordinate.longitude)
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    view.addAnnotation(annotation)
                } else{
                    debugHistory.warn("incomplete location \(String(describing: location)) (lat or long missing)")
                }
            }
        }
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: dLat[0] + (dLat[1] - dLat[0]) / 2,
                longitude: dLong[0] + (dLong[1] - dLong[0]) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.02, (dLat[1] - dLat[0]) * 1.2),
                longitudeDelta: max(0.02, (dLong[1] - dLong[0]) * 1.2)
            )
        )
        
        view.setRegion(region, animated: true)
    }
    
    func setRegion(_ view: MKMapView, _ location:Location?) {
        guard let location = location else {
            return
        }
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        if let lat = location.latitude.value, let long = location.longitude.value {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let region = MKCoordinateRegion(center: coordinate, span: span)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            view.addAnnotation(annotation)
            
            view.setRegion(region, animated: true)
        }
        else {
            print("Cannot make coordinate in setRegion, lat or long missing")
        }
    }

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }

    // MARK: - Implementing MGLMapViewDelegate

    final class Coordinator: NSObject, MGLMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_: MGLMapView, didFinishLoading _: MGLStyle) {}

        func mapView(_: MGLMapView, viewFor _: MGLAnnotation) -> MGLAnnotationView? {
            return nil
        }

        func mapView(_: MGLMapView, annotationCanShowCallout _: MGLAnnotation) -> Bool {
            return true
        }
    }
}*/
