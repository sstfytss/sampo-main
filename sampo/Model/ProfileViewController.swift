//
//  ProfileViewController.swift
//  sampo
//
//  Created by Shun Sakai on 6/16/21.
//

import UIKit
import Firebase
import GoogleSignIn

class ProfileViewController: UIViewController {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var logout: UIButton!
    
    let user = Auth.auth().currentUser

    override func viewDidLoad() {
        super.viewDidLoad()
        name.text = user?.displayName

        // Do any additional setup after loading the view.
    }
    
    
    
    @IBAction func log(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            UserDefaults.standard.set(false, forKey: "loggedin")
            self.dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }

}
