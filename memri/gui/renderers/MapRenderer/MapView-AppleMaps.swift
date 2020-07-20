//
//  MapView.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Combine
import Foundation
import MapKit
import SwiftUI

struct MapView_AppleMaps: UIViewRepresentable {
	var config: MapViewConfig

	func makeUIView(context: Context) -> MKMapView {
		let mapView: MKMapView = MKMapView(frame: .zero)
		mapView.delegate = context.coordinator
		context.coordinator.setup(mapView)

		mapView.alpha = 0

		return mapView
	}

	func updateUIView(_: MKMapView, context: Context) {
		context.coordinator.mapModel.dataItems = config.dataItems
		context.coordinator.mapModel.locationResolver = config.locationResolver
		context.coordinator.mapModel.addressResolver = config.addressResolver
		context.coordinator.mapModel.labelResolver = config.labelResolver
		context.coordinator.mapModel.mapStyle = config.mapStyle
	}

	func makeCoordinator() -> MapView_AppleMaps.Coordinator {
		Coordinator(self)
	}

	// MARK: - Implementing MGLMapViewDelegate

	final class Coordinator: NSObject, MKMapViewDelegate {
		var parent: MapView_AppleMaps
		var mapModel: MapModel = MapModel()

		var mapView: MKMapView?

		var cancellableBag: Set<AnyCancellable> = []

		init(_ parent: MapView_AppleMaps) {
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
				MapMarkerView_AppleMaps.self,
				forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
			)
		}

		var firstSet: Bool = true
		func updateFromModel() {
			guard let mapView = mapView else { return }

			let newAnnotations = mapModel.items.map { item -> MKAnnotation in
				let annotation = MapAnnotation_AppleMaps(
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

		func mapView(_: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped _: UIControl) {
			// ONPRESS
			guard let annotation = view.annotation as? MapAnnotation_AppleMaps, let dataItem = annotation.dataItem else { return }
			parent.config.onPress?(dataItem)
		}
	}
}

class MapAnnotation_AppleMaps: NSObject, MKAnnotation {
	let title: String?
	let coordinate: CLLocationCoordinate2D
	let dataItem: Item?

	init(
		title: String?,
		coordinate: CLLocationCoordinate2D,
		dataItem: Item?
	) {
		self.title = title
		self.coordinate = coordinate
		self.dataItem = dataItem

		super.init()
	}
}

class MapMarkerView_AppleMaps: MKMarkerAnnotationView {
	override var annotation: MKAnnotation? {
		willSet {
			canShowCallout = true
			calloutOffset = .zero
			rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
			// markerTintColor
		}
	}
}
