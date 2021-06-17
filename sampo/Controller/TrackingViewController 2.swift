//
//  TrackingViewController.swift
//  sampo
//
//  Created by Shun Sakai on 6/2/21.
//

import UIKit
import CoreLocation
import MapKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import Cosmos

class TrackingViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,  UITextFieldDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var completeLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var timeStack: UIStackView!
    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var distanceStack: UIStackView!
    @IBOutlet weak var distanceWalked: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var ratingField: CosmosView!
    @IBOutlet weak var stackView: UIStackView!
    
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle!
    var currentUser: User = Auth.auth().currentUser!
    var isWalking = false
    var distance = 0.00
    var timer: Timer = Timer()
    var count: Int = 0
    var counting: Bool = false
    
    @IBOutlet weak var constraintView: UIView!
    var constraintArray: [NSLayoutConstraint] = []
    
    fileprivate let locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    
    var path: [CLLocationCoordinate2D] = []
    var locs: [CLLocation] = []
    let defaults = UserDefaults.standard
    var initial = true
    
    var bottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        mapView.delegate = self
        nameField.delegate = self
        locationManager.delegate = self
        viewSetup()
        setupLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(TrackingViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TrackingViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
         let tap = UITapGestureRecognizer(target: self, action: #selector(TrackingViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        unsubscribeFromAllNotifications()
        self.path.removeAll()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        nameField.text = textField.text
        return true
    }
    
    @IBAction func start(){
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        isWalking = true
        doneButton.isHidden = false
        startButton.isHidden = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        counting = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        
    }
    
    @objc func timerCounter() -> Void{
        count += 1
        let time = secChange(seconds: count)
        let timeString = timeToString(hours: time.0, minutes: time.1, seconds: time.2)
        timeElapsed.text = timeString
    }
    
    func secChange(seconds: Int) -> (Int, Int, Int){
        return ((seconds/3600), ((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }
    
    func timeToString(hours: Int, minutes: Int, seconds: Int) -> String{
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += " : "
        timeString += String(format: "%02d", minutes)
        timeString += " : "
        timeString += String(format: "%02d", seconds)
        return timeString
    }
    
    @IBAction func back(){
        isWalking = false
        distance = 0.00
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue

        let constraint = self.constraintView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -(keyboardFrame.height))
        constraint.isActive = true
        constraintArray.append(constraint)
    }
    
    @objc func dismissKeyboard() {
        nameField.resignFirstResponder()
        view.endEditing(true)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        for c in constraintArray{
            let cc = c
            cc.isActive = false
        }
        constraintArray.removeAll()
    }
    
    @IBAction func done(){
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        let polyline = MKPolyline(coordinates: self.path, count: self.path.count)
        setVisibleMapArea(polyline: polyline, edgeInsets: UIEdgeInsets(top: 60.0, left: 40.0, bottom: 40.0, right: 40.0), animated: true)
        doneButton.isHidden = true
        saveButton.isHidden = false
        topView.isHidden = false
        completeLabel.isHidden = false
        updateSetup()

        self.timer.invalidate()
    }
    
    @IBAction func save(){
        if nameField.hasText == false {
            let alert = UIAlertController(title: "Error", message: "Your sampo route has not been saved. Please enter a name for the route", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            }))
            
            self.present(alert, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Saved", message: "Your Sampo Route Has Been Saved", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                guard let name = self.nameField.text else { return }
                let rating = self.ratingField.rating
                let root = self.ref?.child("Routes")
                let p2 = self.ref?.child("Users")
                let identifier = UUID().uuidString
                let x = self.splitCoordsX()
                let y = self.splitCoordsY()
                root?.child(identifier).child("pathX").setValue(x)
                root?.child(identifier).child("pathY").setValue(y)
                root?.child(identifier).child("name").setValue(name)
                root?.child(identifier).child("rating").setValue(rating)
                root?.child(identifier).child("userid").setValue(self.currentUser.uid)
                root?.child(identifier).child("time").setValue(self.count)
                root?.child(identifier).child("distance").setValue(self.distanceWalked.text)
                self.count = 0
                self.distance = 0.0
                self.timeElapsed.text = self.timeToString(hours: 0, minutes: 0, seconds: 0)
                self.distanceWalked.text = String(0.00)
                
                p2?.child(self.currentUser.uid).child("routes").child(identifier).child("name").setValue(name)
                p2?.child(self.currentUser.uid).child("routes").child(identifier).child("rating").setValue(rating)
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewSetup(){
        //save button is hidden
        saveButton.isHidden = true
        doneButton.isHidden = true
        constraintView.isHidden = true
        
        //frame to show when saving route is hidden
        completeLabel.text = "Walking"
        
        //fields to enter name and rating are hidden
        nameLabel.isHidden = true
        ratingLabel.isHidden = true
        nameField.isHidden = true
        ratingField.isHidden = true
        
        //mapview
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0).isActive = true
        bottomConstraint = NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.timeStack, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: -20)
        bottomConstraint.isActive = true
    }
    
    func updateSetup(){
        //frame to show when saving route is hidden
        completeLabel.text = "Route Recorded"
        
        //fields to enter name and rating are unhidden
        nameLabel.isHidden = false
        ratingLabel.isHidden = false
        nameField.isHidden = false
        ratingField.isHidden = false
        constraintView.isHidden = false
        
        //mapview
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.removeConstraint(bottomConstraint)
        bottomConstraint.isActive = false
        NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.constraintView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: -20).isActive = true
    }
    
    func splitCoordsX() -> [String]{
        let pathArray = self.path
        var xArray: [String] = []
        for i in 0 ..< pathArray.count {
            let x = pathArray[i].latitude
            xArray.append(String(x))
        }
        return xArray
    }
    
    func splitCoordsY() -> [String]{
        let pathArray = self.path
        var yArray: [String] = []
        for i in 0 ..< pathArray.count {
            let y = pathArray[i].longitude
            yArray.append(String(y))
        }
        return yArray
    }
    
    func setupLocation(){
        mapView.showsUserLocation = true
        locationManager.distanceFilter = 20
        locationManager.headingFilter = 30
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //1
        
        if isWalking == true {
            
            if locations.count > 0 {
                let location = locations.last!
                currentLocation = location
                print("Accuracy: \(location.horizontalAccuracy), location: \(locations)")
                
                if self.initial == true {
                    let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    let region = MKCoordinateRegion(center: location.coordinate, span: span)
                    let annotation = Annotation(location: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), title: "Start")
                    self.initial = false
                    DispatchQueue.main.async {
                        self.mapView.addAnnotation(annotation)
                        self.mapView.region = region
                    }
      
                }

                //add updated location to coordinate array
                path.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
                locs.append(CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
                for location in self.locs {
                    if self.locs.count > 0 {
                        distance += location.distance(from: self.locs.last!)
                    }
                }
                distanceWalked.text = String(format: "%.3f", distance/1000)
                print("pathArray: \(path)")
                updatePath()
            }
        }else{
            if let location = locations.last{
                let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.mapView.setRegion(region, animated: true)
            }
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if currentLocation != nil{
            self.path.append(CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude))
            updatePath()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polyLineRender = MKPolylineRenderer(overlay: overlay)
            polyLineRender.strokeColor = UIColor.blue.withAlphaComponent(1)
            polyLineRender.lineWidth = 3

            return polyLineRender
        }
        return MKPolylineRenderer()
    }
    
    func updatePath(){
        if self.path.count > 1{
            if self.path.count == 2{
                let pathWalked = MKPolyline(coordinates: self.path, count: self.path.count)
                self.mapView.addOverlay(pathWalked)
            }else{
                if let overlays = mapView?.overlays {
                    for overlay in overlays {
                        // remove all MKPolyline-Overlays
                        if overlay is MKPolyline {
                            mapView?.removeOverlay(overlay)
                        }
                    }
                }
                let newPath = MKPolyline(coordinates: self.path, count: self.path.count)
                self.mapView.addOverlay(newPath)
            }
        }
    }
    
    func setVisibleMapArea(polyline: MKPolyline, edgeInsets: UIEdgeInsets, animated: Bool = false) {
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: edgeInsets, animated: animated)
    }

}
