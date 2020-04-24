/*
 Copyright © 2019 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 Abstract:
 A view that hosts an `MKMapView`.
 */

import SwiftUI
import MapKit
import RealmSwift

struct MapView: UIViewRepresentable {
    @EnvironmentObject var main: Main
    
    var location: Location? = nil
    var address: Address? = nil
    
    init (location:Location? = nil, address:Address? = nil) {
        self.location = location
        self.address = address
    }
//
//    func searchAddress(_ callback: @escaping (_ items:[MKMapItem]) -> Void){
//        guard let address = address else {
//            return
//        }
//
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = "\(address.street ?? "") \(address.city ?? "") \(address.postalCode ?? "") \(address.state ?? "") \(address.country?.computeTitle ?? "")"
////        request.region = mapView.region
//
//        var matchingItems:[MKMapItem] = []
//        let search = MKLocalSearch(request: request)
//        search.start { response, _ in
//            guard let response = response else {
//                return
//            }
//
//            matchingItems = response.mapItems // What do I do with this?
//
//            callback(matchingItems)
//        }
//    }

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if let address = address {
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
    
    func setRegion(_ view: MKMapView, _ location:Location?) {
        guard let location = location else {
            return
        }
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude.value!, // TODO Refactor error handling?
            longitude: location.longitude.value!
        )
        
        let region = MKCoordinateRegion(center: coordinate, span: span)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        view.addAnnotation(annotation)

        view.setRegion(region, animated: true)
    }
}

extension Address {
    func retrieveLocation(_ callback: @escaping (_ error:Error?) -> Void){
        let request = MKLocalSearch.Request()

        request.naturalLanguageQuery = "\(self.street ?? "") \(self.city ?? "") "
            + "\(self.postalCode ?? "") \(self.state ?? "") \(self.country?.computeTitle ?? "")"

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }

            // TODO Refactor: currently just picking the first one
            if let first = response.mapItems.first {
                try! self.realm!.write { // TODO refactor: error handling
                    let coordinate = first.placemark.coordinate
                    self.location = Location(value: [
                        "longitude": coordinate.longitude,
                        "latitude": coordinate.latitude
                    ])
                }
                
                callback(nil)
            }
            else {
                callback("Unable to get coordinates")
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
  static var previews: some View {
    // Using Artwork object instead of Landmark
    MapView( //coordinate: CLLocationCoordinate2D(latitude: 40, longitude: 0))
        address: Address(value: [
        "street": "1600 Pennsylvania Ave",
        "state": "NW",
        "city": "Washington, DC",
        "postalCode": "20500",
        "country": Country(value: ["name": "United States"])
    ]))
  }
}

// MapView(coordinate: artwork.coordinate)
