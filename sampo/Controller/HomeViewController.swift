//
//  HomeViewController.swift
//  sampo
//
//  Created by Shun Sakai on 5/23/21.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet var myRoutes: UICollectionView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var button: UIButton!
    
    var routes: [String] = []
    var routeInfo: [Route] = []
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle!
    var currentUser: User = Auth.auth().currentUser!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        initiate()
        textField.isHidden = true
        button.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //refresh()
    }
    
    func initiate(){
        self.routes = []
        loadData {
            self.loadRoutes { (r) in
                self.loadNames(r) {
                    self.myRoutes.delegate = self
                    self.myRoutes.dataSource = self
                    self.myRoutes.reloadData()
                    print("done")
                }
            }
        }
    }
    
    func refresh(){
        self.routes = []
        loadData {
            self.loadRoutes { (r) in
                print("r2:\(r)")
                self.loadNames(r) {
                    self.myRoutes.reloadData()
                    print("done:\(self.routeInfo)")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 4, height: collectionView.frame.width / 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("routes: \(routes.count)")
        return self.routeInfo.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = myRoutes.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyRouteCell
        
        cell.number.text = self.routeInfo[indexPath.row].name
        cell.rating.rating = self.routeInfo[indexPath.row].rating ?? 0
        print("rating: \(self.routeInfo[indexPath.row].rating), \(cell.rating.rating)")
        cell.rating.center = self.view.center
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let routeID = self.routeInfo[indexPath.row].id
        defaults.setValue(routeID, forKey: "routeSelected")
        self.performSegue(withIdentifier: "showRoute", sender: self)
    }
    
    func loadData(completion: @escaping () -> ()){
        let path = self.ref.child("Users").child(self.currentUser.uid).child("routes")

        path.observeSingleEvent(of: .value) { (r) in
            for child in r.children.allObjects as! [DataSnapshot] {
                let c = child.key
                self.routes.append(c)
                
            }
            print("child received: \(self.routes)")
            completion()
        }
    }
    
    func loadRoutes(completion: @escaping ([String]) -> ()){
        let path = self.ref.child("Users").child(self.currentUser.uid).child("routes")
        var routes: [String] = []

        path.observeSingleEvent(of: .value) { (r) in
            for child in r.children.allObjects as! [DataSnapshot] {
                let c = child.key
                routes.append(c)
            }
            print("child received: \(self.routes)")
            completion(routes)
        }
    }
    
    func loadNames(_ routes: [String], completion: @escaping () -> ()){
        let path = self.ref.child("Users").child(self.currentUser.uid).child("routes")
        self.routeInfo = []
        //loadData {
        for i in 0 ..< routes.count {
            let r = routes[i]
            path.child(r).child("name").observeSingleEvent(of: .value) { (r2) in
                path.child(r).child("rating").observeSingleEvent(of: .value) { (r3) in
                    guard let name = r2.value as? String else { return }
                    
                    let rating = r3.value as? Double
                    print("success")
                    self.routeInfo.append(Route(id: r, name: name, rating: rating))
                    print("name: \(name), \(self.routeInfo)")
                    
                    if i == routes.count - 1{
                        completion()
                    }
                }
            }
        }

        //}
    }
}
