//
//  SignInViewController.swift
//  sampo
//
//  Created by Shun Sakai on 6/3/21.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase

class SignInViewController: UIViewController, GIDSignInDelegate {
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        setupGoogleButtons()
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func setupScreen(){
        if isKeyPresentInUserDefaults(key: "loggedin") == true {
            let user = Auth.auth().currentUser
            DispatchQueue.main.async {
                //self.performSegue(withIdentifier: "goToHome", sender: self)
            }
        }
    }
    
    fileprivate func setupGoogleButtons(){
        //add google sign in button
        let googleButton = GIDSignInButton()
        googleButton.frame = CGRect(x: 16, y: view.frame.height - 130, width: view.frame.width - 32, height: view.frame.height - 30)
        view.addSubview(googleButton)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
          print(error)
          return
        }else{
            print("useremail: \(user.profile.email ?? "no email")")
            
            guard let idToken = user.authentication.idToken else { return }
            guard let accessToken = user.authentication.accessToken else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
            accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { (user, error) in
                if error == nil{
                    print("successfully created firebase user")
                    UserDefaults.standard.set(true, forKey: "loggedin")

                    let user = Auth.auth().currentUser
                    let root = self.ref?.child("Users")
                    
                    if let user = user {
                        let email = user.email
                        let id = user.uid
                        
                        root?.observeSingleEvent(of: .value, with: { (snapshot) in
                            print("snapshot2: \(snapshot.value)")
                            if snapshot.hasChild(id){
                                //go to home
                                self.performSegue(withIdentifier: "goToHome", sender: self)

                            }else{//id does not exist in database
                                root?.child(id).child("email").setValue(email)
                                self.performSegue(withIdentifier: "goToHome", sender: self)
                                return
                            }
                        })
                    }
                    
                }else{
                    print(error?.localizedDescription)
                }
                
            }
        }
    }
}
