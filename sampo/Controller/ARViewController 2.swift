//
//  ARViewController.swift
//  sampo
//
//  Created by Shun Sakai on 5/30/21.
//

import UIKit
import ARCL
import CoreLocation
import MapKit
import Firebase

class ARViewController: UIViewController {
    var sceneLocationView = SceneLocationView()
    var coordinates: [CLLocationCoordinate2D] = []
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle!
    let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
        
        loadData { (x) in
            print("xRec: \(x)")
            self.loadData2 { (y) in
                print("yRec: \(y)")
                self.setData(x, y) { (coords) in
                    let polyline = MKPolyline(coordinates: coords, count: coords.count)
                    self.sceneLocationView.addPolylines(polylines: [polyline])
                    self.sceneLocationView.addSubview(self.button)
                }
            }
        }
        
        let coordinate2 = CLLocationCoordinate2D(latitude: 35.65199745, longitude: 140.05476916)
        
        let location = CLLocation(coordinate: coordinate2, altitude: 0)
        let image = UIImage(named: "pin2")!

        let annotationNode = LocationAnnotationNode(location: location, image: image)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)

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
    
    func setData(_ x: [Double], _ y: [Double], completion: ([CLLocationCoordinate2D]) -> ()){
        var coordinates2:[CLLocationCoordinate2D] = []
        for i in 0 ..< x.count {
            let set = CLLocationCoordinate2D(latitude: x[i], longitude: y[i])
            coordinates2.append(set)
        }
        completion(coordinates2)
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()

      sceneLocationView.frame = view.bounds
    }

}
