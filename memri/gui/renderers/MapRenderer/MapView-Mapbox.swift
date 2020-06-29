//
import Combine
//  MapView.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//
import Foundation
import SwiftUI

struct MapViewConfig {
	var dataItems: [DataItem] = []
	var locationKey: String = "coordinate"
	var addressKey: String = "address"
	var labelKey: String = "name"
	var maxInitialZoom: Double = 16
	var mapStyle: MapStyle = .street

	var onPress: ((DataItem) -> Void)?

	@Environment(\.colorScheme) var colorScheme
}

#if !targetEnvironment(macCatalyst)
	import Mapbox

	struct MapView_Mapbox: UIViewRepresentable {
		var config: MapViewConfig

		@Environment(\.colorScheme) var colorScheme
		func makeUIView(context: Context) -> MGLMapView {
			let mapView: MGLMapView = MGLMapView(frame: .zero, styleURL: MGLStyle.streetsStyleURL)
			mapView.delegate = context.coordinator
			context.coordinator.mapView = mapView

			// Move logo and info button to bottomRight with minimal margins
			mapView.attributionButtonPosition = .bottomRight
			mapView.attributionButtonMargins = .init(x: 5, y: 5)
			mapView.logoViewPosition = .bottomRight
			mapView.logoViewMargins = .init(x: 35, y: 6)

			return mapView
		}

		func updateUIView(_: MGLMapView, context: Context) {
			context.coordinator.mapModel.dataItems = config.dataItems
			context.coordinator.mapModel.locationKey = config.locationKey
			context.coordinator.mapModel.addressKey = config.addressKey
			context.coordinator.mapModel.labelKey = config.labelKey
			context.coordinator.mapModel.mapStyle = config.mapStyle
		}

		func makeCoordinator() -> MapView_Mapbox.Coordinator {
			Coordinator(self)
		}

		// MARK: - Implementing MGLMapViewDelegate

		final class Coordinator: NSObject, MGLMapViewDelegate {
			var parent: MapView_Mapbox
			var mapModel: MapModel = MapModel()

			var mapView: MGLMapView?

			var cancellableBag: Set<AnyCancellable> = []

			init(_ parent: MapView_Mapbox) {
				self.parent = parent
				super.init()

				mapModel.didChange.sink { [weak self] in
					self?.updateFromModel()
				}
				.store(in: &cancellableBag)
			}

			func updateFromModel() {
				guard let mapView = mapView else { return }
				mapView.styleURL = mapModel.mapStyle.url(preferDark: parent.colorScheme == .dark)

				let newAnnotations = mapModel.items.map { item -> MGLAnnotation in
					let annotation = MapAnnotation_Mapbox(
						coordinate: item.coordinate,
						title: item.label,
						dataItem: item.dataItem
					)
					return annotation
				}
				mapView.annotations.map { mapView.removeAnnotations($0) }
				mapView.addAnnotations(newAnnotations)

				// Set initial position
				getBoundsToFit().map {
					mapView.setVisibleCoordinateBounds($0, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false, completionHandler: {})
					if mapView.zoomLevel > parent.config.maxInitialZoom {
						mapView.setZoomLevel(parent.config.maxInitialZoom, animated: false)
					}
				}
			}

			func getBoundsToFit() -> MGLCoordinateBounds? {
				guard let firstCoord = mapModel.items.first?.coordinate else { return nil }
				let bounds = mapModel.items.reduce(into: MGLCoordinateBounds(sw: firstCoord, ne: firstCoord))
				{ bounds, dataPoint in
					if dataPoint.coordinate.latitude < bounds.sw.latitude { bounds.sw.latitude = dataPoint.coordinate.latitude }
					if dataPoint.coordinate.latitude > bounds.ne.latitude { bounds.ne.latitude = dataPoint.coordinate.latitude }
					if dataPoint.coordinate.longitude < bounds.sw.longitude { bounds.sw.longitude = dataPoint.coordinate.longitude }
					if dataPoint.coordinate.longitude > bounds.ne.longitude { bounds.ne.longitude = dataPoint.coordinate.longitude }
				}
				// TODO: Consider what will happen if there are points just either side of the meridian??
				return bounds
			}

			func mapView(_: MGLMapView, didFinishLoading _: MGLStyle) {
				//
			}

			func mapView(_: MGLMapView, viewFor _: MGLAnnotation) -> MGLAnnotationView? {
				nil
			}

			func mapView(_: MGLMapView, annotationCanShowCallout _: MGLAnnotation) -> Bool {
				true
			}

			func mapView(_: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
				// ONPRESS
				guard let annotation = annotation as? MapAnnotation_Mapbox, let dataItem = annotation.dataItem else { return }
				parent.config.onPress?(dataItem)
			}
		}
	}

	class MapAnnotation_Mapbox: NSObject, MGLAnnotation {
		init(coordinate: CLLocationCoordinate2D, title: String? = nil, dataItem: DataItem? = nil) {
			self.coordinate = coordinate
			self.title = title
			self.dataItem = dataItem
		}

		var coordinate: CLLocationCoordinate2D
		var title: String?
		var dataItem: DataItem?
	}

#endif
