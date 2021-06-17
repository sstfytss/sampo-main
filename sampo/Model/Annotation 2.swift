//
//  Annotation.swift
//  sampo
//
//  Created by Shun Sakai on 5/27/21.
//

import Foundation
import MapKit

class Annotation: NSObject, MKAnnotation{
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    init(location: CLLocationCoordinate2D, title: String) {
      self.coordinate = location
      self.title = title
      
      super.init()
    }
}
