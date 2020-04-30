import SwiftUI
import MapKit
import RealmSwift

struct MapView: UIViewRepresentable {
    @EnvironmentObject var main: Main
    
    var location: Location? = nil
    var address: Address? = nil
    
    var locations: [Location]? = nil
    var addresses: [Address]? = nil
    
    init (location:Location? = nil, address:Address? = nil) {
        self.location = location
        self.address = address
    }
    
    init (locations:[Location]? = nil, addresses:[Address]? = nil) {
        self.locations = locations
        self.addresses = addresses
    }

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
        for location in locations! {
            let coordinate = CLLocationCoordinate2D(
                latitude: location!.latitude.value!, // TODO Refactor error handling?
                longitude: location!.longitude.value!
            )
            
            dLat[0] = min(dLat[0], coordinate.latitude)
            dLat[1] = max(dLat[1], coordinate.latitude)
            
            dLong[0] = min(dLong[0], coordinate.longitude)
            dLong[1] = max(dLong[1], coordinate.longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            view.addAnnotation(annotation)
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
            + "\(self.postalCode ?? "") \(self.state ?? "") \(self.country?.computedTitle ?? "")"

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                callback("Unknown error")
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
