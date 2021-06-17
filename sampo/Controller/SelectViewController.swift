//
//  SelectViewController.swift
//  sampo
//
//  Created by Shun Sakai on 5/27/21.
//

import UIKit
import MapKit
import CoreLocation
import HDAugmentedReality
import Firebase
import FirebaseAuth

class SelectViewController: UIViewController, MKMapViewDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    let defaults = UserDefaults.standard
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle!
    var currentUser: User = Auth.auth().currentUser!
    var coordinates: [CLLocationCoordinate2D] = []
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var startedLoadingPOIs = false
    fileprivate var placesArray = [Place]()
    fileprivate var annotationArray = [Annotation]()
    fileprivate var arViewController: ARViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        mapView.delegate = self
        
        loadData { (x) in
            print("xRec: \(x)")
            self.loadData2 { (y) in
                print("yRec: \(y)")
                self.loadData3 { name in
                    self.nameLabel.text = name
                    self.loadData4 { time in
                        self.loadData5 { distance in
                            self.distanceLabel.text = "\(time), \(distance) km"
                            self.setData(x, y) { (coords) in
                                let polyline = MKPolyline(coordinates: coords, count: coords.count)
                                self.mapView.addOverlay(polyline)
                                self.setVisibleMapArea(polyline: polyline, edgeInsets: UIEdgeInsets(top: 60.0, left: 40.0, bottom: 40.0, right: 40.0), animated: true)
                            }
                        }
                    }
                }
            }
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadData(completion: @escaping ([Double]) -> ()){
        guard let rID = defaults.value(forKey: "routeSelected") as? String else { return }
        let path = self.ref.child("Routes").child(rID)
        var xArray: [Double] = []
        path.child("pathX").observeSingleEvent(of: .value) { (snap) in
            for x in snap.children.allObjects as! [DataSnapshot]{
                let x2 = x.value as! String
                let xDouble = (x2 as NSString).doubleValue
                xArray.append(xDouble)
            }
            completion(xArray)
        }
    }
    
    func loadData2(completion: @escaping ([Double]) -> ()){
        guard let rID = defaults.value(forKey: "routeSelected") as? String else { return }
        let path = self.ref.child("Routes").child(rID)
        var yArray: [Double] = []
        path.child("pathY").observeSingleEvent(of: .value) { (snap2) in
            for y in snap2.children.allObjects as! [DataSnapshot]{
                let y2 = y.value as! String
                let yDouble = (y2 as NSString).doubleValue
                yArray.append(yDouble)
            }
            completion(yArray)
        }
    }
    
    func loadData3(completion: @escaping (String) -> ()){
        guard let rID = defaults.value(forKey: "routeSelected") as? String else { return }
        let path = self.ref.child("Routes").child(rID).child("name")
        path.observeSingleEvent(of: .value) { (snap2) in
            let name = snap2.value as! String
            completion(name)
        }
    }
    
    func loadData4(completion: @escaping (String) -> ()){
        guard let rID = defaults.value(forKey: "routeSelected") as? String else { return }
        let path = self.ref.child("Routes").child(rID).child("time")
        path.observeSingleEvent(of: .value) { (snap2) in
            let t = snap2.value as! Int
            let time = self.secChange(seconds: t)
            let timeString = self.timeToString(hours: time.0, minutes: time.1, seconds: time.2)
            completion(timeString)
        }
    }
    
    func loadData5(completion: @escaping (String) -> ()){
        guard let rID = defaults.value(forKey: "routeSelected") as? String else { return }
        let path = self.ref.child("Routes").child(rID).child("distance")
        path.observeSingleEvent(of: .value) { (snap2) in
            let d = snap2.value as! String
            completion(d)
        }
    }
    
    
    func secChange(seconds: Int) -> (Int, Int, Int){
        return ((seconds/3600), ((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }
    
    func timeToString(hours: Int, minutes: Int, seconds: Int) -> String{
        var timeString = ""
        
        if hours != 0 {
            timeString += String(format: "%02d", hours)
            timeString += " hrs "
            timeString += String(format: "%02d", minutes)
            timeString += " mins "
            timeString += String(format: "%02d", seconds)
            timeString += " secs"
        }else if hours == 0 && minutes != 0{
            timeString += String(format: "%02d", minutes)
            timeString += " mins "
            timeString += String(format: "%02d", seconds)
            timeString += " secs"
        }else if hours == 0 && minutes == 0{
            timeString += String(format: "%02d", seconds)
            timeString += " secs"
        }
        return timeString
    }
    
    func setData(_ x: [Double], _ y: [Double], completion: ([CLLocationCoordinate2D]) -> ()){
        var coordinates2:[CLLocationCoordinate2D] = []
        for i in 0 ..< x.count {
            let set = CLLocationCoordinate2D(latitude: x[i], longitude: y[i])
            coordinates2.append(set)
        }
        completion(coordinates2)
    }
    
    func setupLocation(){
        
    }
    
    func getDistance(){
        
    }
    
    func setVisibleMapArea(polyline: MKPolyline, edgeInsets: UIEdgeInsets, animated: Bool = false) {
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: edgeInsets, animated: animated)
    }

}

extension SelectViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //1
        if locations.count > 0 {
            let location = locations.last!
            print("Accuracy: \(location.horizontalAccuracy), location: \(location)")
            
            if location.horizontalAccuracy < 100 {
                //3
                manager.stopUpdatingLocation()
                let span = MKCoordinateSpan(latitudeDelta: 0.014, longitudeDelta: 0.014)
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                mapView.region = region
                
                if !startedLoadingPOIs {
                    startedLoadingPOIs = true
                    //1
                    for place in placesArray {
                        //3
                        guard let latitude = place.x else { return }
                        guard let longitude = place.y else { return }

                        let annotation = Annotation(location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: "place.placeName")
                        annotationArray.append(annotation)
                        DispatchQueue.main.async {
                            self.mapView.addAnnotation(annotation)
                        }
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = UIColor.blue.withAlphaComponent(0.9)
            renderer.lineWidth = 7
            return renderer
        }

        return MKOverlayRenderer()
    }
    
}

