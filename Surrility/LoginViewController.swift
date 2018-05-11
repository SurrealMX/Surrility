//
//  LoginViewController.swift
//  Surrility
//
//  Created by Administrator on 3/1/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

var UserEmail: String? = nil
var UserId: String? = nil
var UserName: String? = nil

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var fbButton: FBSDKLoginButton!
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if (error != nil) {
            print("login failed")
            return
        }
        imLoggedIn()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        // Do any additional setup after loading the view.
        fbButton.backgroundColor = UIColor.darkGray
        fbButton.setTitle("Continue with Facebook", for: UIControlState.normal)
        fbButton.readPermissions = ["email", "public_profile"]
        fbButton.delegate = self
        //persistent login
        if (FBSDKAccessToken.current()) != nil {
            //well i was already logged in
            imLoggedIn()
        }
    }
    
    func imLoggedIn(){
        //login to surility
        loginToSurility()
        
        //lets grab the user's info from FB
        fetchFBdata()
        
        //move to the camera app
        moveAction()
    }
    
    func fetchFBdata(){
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, err) in
            
            if err != nil {
                print("failed to start graph request:", err!)
                return
            }
            let results = result as! [String: AnyObject]
            UserEmail = results["email"] as? String
            //UserId = results["id"] as? String
            UserName = results["name"] as? String
            print(result!)
        }
    }
    
    func moveAction(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Camera") as! CameraViewController
        
        self.show(vc, sender: nil)
        //self.navigationController?.pushViewController(vc, animated: true)
        //self.present(vc, animated: true, completion: nil)
    }
    
    
    func loginToSurility() {
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print("Couldn't Sign into Firebase")
                return
            }
            print("Successfully Logged on to Firebase with user from FB: ", user ?? "")
            UserId = user?.uid
            self.updateUserRecord()
        }
    }
    
    func updateUserRecord(){
        //create a referene to the database
        let ref = Database.database().reference()
        
        //get the serverTimeStamp
        let timeStamp = Firebase.ServerValue.timestamp()
        
        //update our records to show the user logged on
        let tempRef = ref.child("Users").child(UserId!).childByAutoId().parent  //get reference to user
        //add Name
        tempRef?.child("Name").setValue(UserName)
        //add email
        tempRef?.child("Email").setValue(UserEmail)
        //setup likes
        tempRef?.child("likes").setValue(0)
        //update the last time the user logged on
        tempRef?.child("Last_Logon").setValue(timeStamp)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
