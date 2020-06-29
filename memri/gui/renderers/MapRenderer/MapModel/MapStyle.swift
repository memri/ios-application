//
//  MapStyle.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 19/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

enum MapStyle: Equatable {
    case street
    case minimal
    case blueprint
    case outdoors
    case satellite
    case custom(URL)
    
    func url(preferDark: Bool) -> URL {
        switch self {
        case .street:
            return URL(string: "mapbox://styles/mapbox/streets-v11")!
        case .minimal:
            return preferDark ? URL(string: "mapbox://styles/mapbox/dark-v10")! : URL(string: "mapbox://styles/mapbox/light-v10")!
        case .outdoors:
            return URL(string: "mapbox://styles/mapbox/outdoors-v11")!
        case .satellite:
            return URL(string: "mapbox://styles/mapbox/satellite-streets-v11")!
        case .blueprint:
            return URL(string: "mapbox://styles/apptekstudios/ckb1nhkez0dkb1ilmtqb9qint")!
        case let .custom(url):
            return url
        }
    }
    
    init(fromString string: String?) {
        switch string {
        case "street":
            self = .street
            return
        case "minimal":
            self = .minimal
            return
        case "blueprint":
            self = .blueprint
            return
        case "outdoors":
            self = .outdoors
            return
        case "satellite":
            self = .satellite
            return
        case .some(let string):
            self = URL(string: string).map { .custom($0) } ?? .street
            return
        case .none:
            self = .street
            return
        }
    }
}
